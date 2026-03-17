@EndUserText.label: 'Booking Proj View for Draft RefScen'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true
define view entity YC_Booking_A_D
  as projection on YR_BOOKING_D
{
  key BookingUUID,

      TravelUUID,

      @Search.defaultSearchElement: true
      BookingID,

      BookingDate,

      @ObjectModel.text.element: ['CustomerName']
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Customer_StdVH', element: 'CustomerID' } }]
      CustomerID,
      _Customer.LastName        as CustomerName,

      @ObjectModel.text.element: ['CarrierName']

      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Flight', element: 'AirlineID' },
                                           additionalBinding: [ { localElement: 'FlightDate',   element: 'FlightDate',usage: #RESULT },
                                                                { localElement: 'AirlineID',    element: 'AirlineID',usage: #RESULT },
                                                                { localElement: 'FlightPrice',  element: 'Price', usage: #RESULT},
                                                                { localElement: 'CurrencyCode', element: 'CurrencyCode', usage: #RESULT } ] } ]  
      AirlineID,
      _Carrier.Name             as CarrierName,

      @Consumption.valueHelpDefinition: [ {entity: {name: '/DMO/I_Flight', element: 'ConnectionID'},
                           additionalBinding: [ { localElement: 'FlightDate',   element: 'FlightDate'},
                                                { localElement: 'AirlineID',    element: 'AirlineID'},
                                                { localElement: 'FlightPrice',  element: 'Price', usage: #RESULT},
                                                { localElement: 'CurrencyCode', element: 'CurrencyCode', usage: #RESULT } ] } ]
      ConnectionID,

      FlightDate,
      FlightPrice,

      @Consumption.valueHelpDefinition: [{entity: {name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true }]
      CurrencyCode,

      @ObjectModel.text.element: ['BookingStatusText']
      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Booking_Status_VH', element: 'BookingStatus' }}]
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,

//yt_booking_d상에 _airport로 table function으로 지정한 view의 city정보를 asscioation으로 지정한 내용을 이곳에서 사용할 수 있다.
      YR_BOOKING_D._Airport.city as City,
//virtual element를 지정하는 방법임. class는 생성할때 interface에 if_sadl_exit_calc_element_read 를 넣어줘야함  
//abstract entity는 cds view로서 기존 cds view에 없는 구조나 필드로 선언해서 action에서 parameter로 쓰기 위해 사용하는 것이고, virtual element는 abap logic을 사용해서
// 필드를 추가하고자 할때 사용하는 것이다.     
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:YCL_READ_TEXT'
      virtual ltext : abap.char( 40 ),
      LocalLastChangedAt, 

      /* Associations */
      _BookingSupplement : redirected to composition child YC_BookingSupplement_A_D,
      _BookingStatus,
      _Carrier,
      _Connection,
      _Customer,
      _Travel            : redirected to parent YC_TRAVEL_A_D
}
