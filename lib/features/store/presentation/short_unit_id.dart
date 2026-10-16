/// Id de bulto abreviado para listas (los ids son UUID largos).
String shortUnitId(String unitId) =>
    unitId.length <= 8 ? unitId : '…${unitId.substring(unitId.length - 6)}';
