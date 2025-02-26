codeunit 50002 "WhseCreateSourceDocumentEvents"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", 'OnBeforeCreateShptLineFromSalesLine', '', false, false)]
    internal procedure OnBeforeCreateShptLineFromSalesLineEvent(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        WarehouseShipmentLine."Lookup Value Code" := SalesHeader."Lookup Value Code";
    end;
}