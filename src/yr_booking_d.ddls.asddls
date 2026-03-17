@EndUserText.label: 'Booking View Entity for Draft RefScen'
@AccessControl.authorizationCheck: #NOT_REQUIRED

define view entity YR_BOOKING_D as select from /dmo/a_booking_d

  association        to parent YR_TRAVEL_D as _Travel        on  $projection.TravelUUID = _Travel.TravelUUID
  composition [0..*] of YR_BookingSupplement_D as _BookingSupplement

  association [1..1] to /DMO/I_Customer            as _Customer      on  $projection.CustomerID = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier             as _Carrier       on  $projection.AirlineID = _Carrier.AirlineID
  association [1..1] to /DMO/I_Connection          as _Connection    on  $projection.AirlineID    = _Connection.AirlineID
                                                                     and $projection.ConnectionID = _Connection.ConnectionID
  association [1..1] to /DMO/I_Booking_Status_VH   as _BookingStatus on  $projection.BookingStatus = _BookingStatus.BookingStatus
  
// table function을 사용하기 위해 정의함. booking에 있는 connectionid로 airport_to로 연결된 airport city와 country정보를 읽어온다.
// 여기 view에서는 association으로 연결한 정보를 바로 쓸 수는 없고, 이 view를 사용한 view에서 사용할 수 있는데, 
// 또한 여기 view에 tf에 사용할 필드가 이미 존재해야한다 _asso에 있는 필드는 사용할 수 없다.
// 원래는 aggregation view를 별도로 두고 _R로 만든 view를 _I에서 사용하고, consumption view에서는 최종적으로 expose할 것만 남기게 되는데,
// 여기서는 table function 사용법을 보여주기 위해 이렇게 사용함 여기서는 yc_booking_a_d에서 city필드를 사용함 
  association to yr_airport_tf as _Airport on $projection.ConnectionID = _Airport.connection
{ 
  key booking_uuid          as BookingUUID,
      parent_uuid           as TravelUUID,

      booking_id            as BookingID,
      booking_date          as BookingDate,
      customer_id           as CustomerID,
      carrier_id            as AirlineID,
      connection_id         as ConnectionID,
      flight_date           as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      currency_code         as CurrencyCode,
      booking_status        as BookingStatus,

      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      //Associations
      _Travel,
      _BookingSupplement,

      _Customer,
      _Carrier,
      _Connection, 
      _BookingStatus,
      _Airport
}
