# 📦 QuantumERP Pro v4.0 — Sistema ERP, POS FEL (SAT) & Kardex Forense SQL

![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)

Sistema Empresarial de Planificación de Recursos (ERP), Punto de Venta Comercial con **Facturación Electrónica FEL (Guatemala)**, Reabastecimiento **B2B vía WhatsApp** y **Kardex Forense gobernado por Triggers Transaccionales en MySQL**.

## 🚀 Características Principales
- **Terminal POS con Facturación FEL (SAT):** Cálculo automático de Subtotal e IVA (12%), validación de NIT y emisión de **Ticket Térmico de 80mm** listo para impresora.
- **Protección Anti-Stock Negativo a Nivel de Motor SQL:** Trigger `BEFORE INSERT` (`trg_procesar_movimiento_kardex`) con bloqueo de fila (`FOR UPDATE`) y excepción nativa `SIGNAL SQLSTATE '45000'`.
- **Pedidos B2B Automatizados por WhatsApp:** Detección de stock mínimo y generación de orden de compra directa al WhatsApp del proveedor.
- **Etiquetado de Activos con Código QR y Corte de Caja (Reporte Z):** Arqueo diario por Efectivo, Tarjeta POS y Transferencias.

## 🛠️ Instalación y Despliegue Local
1. Ejecutar el script `database.sql` en MySQL.
2. Instalar dependencias: `pip install fastapi uvicorn mysql-connector-python pydantic`
3. Iniciar servidor API: `uvicorn main:app --reload`
4. Abrir `index.html` en el navegador.

---
**Desarrollado por:** Derek José Ramos Bar — *Ingeniería en Ciencias y Sistemas (USAC)*