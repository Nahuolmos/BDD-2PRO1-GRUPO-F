# spec: FNBC control_lote_almacen

Objetivo: Unidad 4 Parte 1 — demostrar violación FNBC y descomposición sin pérdida.

Esquema: control_lote_almacen(LoteID, DepositoID, ResponsableControlID), PK(LoteID, DepositoID).
DF1: {LoteID, DepositoID} -> ResponsableControlID (PK).
DF2: ResponsableControlID -> DepositoID (cada responsable pertenece a un único depósito).

Claves candidatas: {LoteID, DepositoID} y {LoteID, ResponsableControlID}. Primos: los 3. Violación: R->D con R no superclave.

Descomposición Heath sobre DF violatoria:
- R1 responsable_deposito(ResponsableControlID PK, DepositoID) captura R->D
- R2 control_lote(LoteID, ResponsableControlID PK) captura {L,R}
- Común: ResponsableControlID, PK en R1 => join sin pérdida.
- Vista v_control_lote_almacen = R1 JOIN R2 reconstruye original.

Adaptación repo: este repo usa cliente (schema.sql:49), no usuario. Se crea stub usuario(id) solo para este TP para respetar REFERENCES usuario(id) de la consigna. lote/deposito tampoco existen, se crean IF NOT EXISTS.
