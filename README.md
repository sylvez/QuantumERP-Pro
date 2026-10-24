# 📦 QuantumERP Pro v5.0 — Sistema ERP, POS Láser FEL (SAT), BI Analytics & Kardex Forense SQL

**Propietario y Desarrollador Principal:** Kevin Alejandro Vásquez Ramos

![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)

Sistema Empresarial de Planificación de Recursos (ERP), Punto de Venta con **Modo Pistola Láser USB**, **Facturación Electrónica FEL (Guatemala)**, Cálculo de **Ganancia Neta Real**, Gráficas Ejecutivas (**Chart.js**), Reabastecimiento **B2B vía WhatsApp** y **Kardex Forense gobernado por Triggers Transaccionales en MySQL**.

## 🚀 Características Principales
- **Terminal POS con Escáner Láser y Facturación FEL (SAT):** Disparo automático por código SKU con confirmación auditiva (*Beep*), cálculo de IVA (12%), validación de NIT y **Ticket Térmico de 80mm**.
- **Protección Anti-Stock Negativo a Nivel de Motor SQL:** Trigger `BEFORE INSERT` (`trg_procesar_movimiento_kardex`) con bloqueo de fila (`FOR UPDATE`) y excepción nativa `SIGNAL SQLSTATE '45000'`.
- **Estado de Resultados Diario y Corte de Caja (Reporte Z):** Cálculo en tiempo real de **Utilidad Neta Limpia** (Precio Venta menos Costo Unitario) y arqueo por Efectivo, Tarjeta POS y Transferencias.
- **BI Analytics & Pedidos B2B por WhatsApp:** Gráficas gerenciales interactivas, etiquetas QR de activos y órdenes de compra directas al proveedor.

## 🛠️ Instalación y Despliegue Local
1. Ejecutar el script `database.sql` en MySQL.
2. Instalar dependencias: `pip install fastapi uvicorn mysql-connector-python pydantic`
3. Iniciar servidor API: `uvicorn main:app --reload`
4. Abrir `index.html` en el navegador.

---
**Propiedad Intelectual y Desarrollo:** Kevin Alejandro Vásquez Ramos — *Ingeniería en Ciencias y Sistemas (USAC)*