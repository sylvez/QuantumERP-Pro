from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import mysql.connector
from mysql.connector import Error
import uuid
from datetime import datetime

app = FastAPI(
    title="QuantumERP Pro v4.0 API",
    description="Backend Empresarial ERP, POS FEL, Kardex Forense y Corte de Caja Z",
    version="4.0.0"
)

# Habilitar CORS para permitir peticiones desde el Frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración de conexión a MySQL nativo
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "202502241",  # <-- Coloca aquí tu contraseña de MySQL si tienes una configurada
    "database": "quantum_erp_db"
}

def get_db_connection():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Error de conexión a MySQL: {str(e)}")

# ================= MODELOS PYDANTIC =================
class ProductoCreate(BaseModel):
    sku: str
    nombre: str
    categoria: str
    costo_unitario: float
    precio_venta: float
    stock_minimo: int = 5
    proveedor_nombre: str = "Distribuidora Mayorista GT"
    proveedor_tel: str = "50255551234"

class MovimientoCreate(BaseModel):
    producto_id: int
    tipo_movimiento: str  # 'ENTRADA' o 'SALIDA'
    cantidad: int
    referencia: str
    usuario_responsable: str = "Derek Ramos"

class ItemCarritoPOS(BaseModel):
    producto_id: int
    cantidad: int
    precio_venta: float

class FacturaPOSCreate(BaseModel):
    nit_cliente: str = "CF"
    nombre_cliente: str = "Consumidor Final"
    metodo_pago: str = "EFECTIVO"  # 'EFECTIVO', 'TARJETA_POS', 'TRANSFERENCIA'
    cajero: str = "Derek Ramos"
    items: List[ItemCarritoPOS]

# ================= ENDPOINTS API RESTful =================

@app.get("/api/dashboard")
def obtener_datos_completos():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM productos ORDER BY id ASC")
        productos = cursor.fetchall()

        cursor.execute("""
            SELECT k.*, p.nombre AS producto_nombre
            FROM kardex_auditoria k
            JOIN productos p ON k.producto_id = p.id
            ORDER BY k.id DESC LIMIT 100
        """)
        kardex = cursor.fetchall()

        cursor.execute("SELECT * FROM facturas_fel ORDER BY id DESC LIMIT 50")
        facturas = cursor.fetchall()

        return {
            "status": "ok",
            "productos": productos,
            "kardex": kardex,
            "facturas": facturas
        }
    finally:
        cursor.close()
        conn.close()

@app.post("/api/productos")
def crear_producto(prod: ProductoCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            INSERT INTO productos (sku, nombre, categoria, costo_unitario, precio_venta, stock_actual, stock_minimo, proveedor_nombre, proveedor_tel)
            VALUES (%s, %s, %s, %s, %s, 0, %s, %s, %s)
        """, (prod.sku, prod.nombre, prod.categoria, prod.costo_unitario, prod.precio_venta, prod.stock_minimo, prod.proveedor_nombre, prod.proveedor_tel))
        conn.commit()
        return {"mensaje": "Producto registrado exitosamente en el catálogo", "id": cursor.lastrowid}
    except Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cursor.close()
        conn.close()

@app.post("/api/movimientos")
def registrar_movimiento(mov: MovimientoCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        # Al insertar en movimientos, el Trigger trg_procesar_movimiento_kardex se ejecuta automáticamente
        cursor.execute("""
            INSERT INTO movimientos (producto_id, tipo_movimiento, cantidad, referencia, usuario_responsable)
            VALUES (%s, %s, %s, %s, %s)
        """, (mov.producto_id, mov.tipo_movimiento, mov.cantidad, mov.referencia, mov.usuario_responsable))
        conn.commit()
        return {"mensaje": "Movimiento procesado y auditado en Kardex exitosamente"}
    except Error as e:
        conn.rollback()
        # Si el trigger lanza SIGNAL SQLSTATE '45000', capturamos el mensaje exacto de MySQL
        raise HTTPException(status_code=400, detail=e.msg)
    finally:
        cursor.close()
        conn.close()

@app.post("/api/pos/facturar")
def emitir_factura_pos_fel(venta: FacturaPOSCreate):
    if not venta.items:
        raise HTTPException(status_code=400, detail="El carrito de venta está vacío.")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        # Generar número de Autorización DTE SAT simulado
        dte_uuid = f"DTE-FEL-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
        total_venta = sum(item.cantidad * item.precio_venta for item in venta.items)
        subtotal_sin_iva = round(total_venta / 1.12, 2)
        iva_12 = round(total_venta - subtotal_sin_iva, 2)

        # 1. Descontar cada producto disparando el Trigger transaccional de MySQL
        for item in venta.items:
            cursor.execute("""
                INSERT INTO movimientos (producto_id, tipo_movimiento, cantidad, referencia, usuario_responsable)
                VALUES (%s, 'SALIDA', %s, %s, %s)
            """, (item.producto_id, item.cantidad, f"VENTA POS {dte_uuid} | NIT: {venta.nit_cliente}", venta.cajero))

        # 2. Registrar la factura electrónica FEL
        cursor.execute("""
            INSERT INTO facturas_fel (numero_dte, nit_cliente, nombre_cliente, metodo_pago, subtotal_sin_iva, iva_12, total_facturado, cajero)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (dte_uuid, venta.nit_cliente, venta.nombre_cliente, venta.metodo_pago, subtotal_sin_iva, iva_12, total_venta, venta.cajero))

        conn.commit()
        return {
            "mensaje": "Factura FEL certificada y stock descontado en Kardex",
            "numero_dte": dte_uuid,
            "total": total_venta,
            "subtotal": subtotal_sin_iva,
            "iva": iva_12
        }
    except Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=e.msg)
    finally:
        cursor.close()
        conn.close()