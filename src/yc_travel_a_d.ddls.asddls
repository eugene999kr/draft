@EndUserText.label: 'Travel Projection View for Draft RefScen'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity YC_TRAVEL_A_D
  provider contract transactional_query
 as projection on YR_TRAVEL_D
{
  key TravelUUID,

      @Search.defaultSearchElement: true
      TravelID,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['AgencyName']
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Agency_StdVH', element: 'AgencyID'  }, useForValidation: true }]
      AgencyID,
      _Agency.Name       as AgencyName,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerName']
      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Customer_StdVH', element: 'CustomerID' } }]
      CustomerID,
      _Customer.LastName as CustomerName,

      BeginDate,

      EndDate,

      BookingFee,

      TotalPrice,

      @Consumption.valueHelpDefinition: [{entity: {name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true }]
      CurrencyCode,

      Description,
      
// overalstatus는 Domain: /DMO/OVERALL_STATUS 유형이고,  한정된 값을 갖는 domain으로 사용하고 selectionField기능을 metadata ext에 지정하면
// f4필드가 아니라 dropdown listbox형태로 보여지게 된다.       
// 그런데, @consumption.filter.defaultvalue를 지정하면 기본값을 지정할 수 있다.
      @ObjectModel.text.element: ['OverallStatusText']
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Overall_Status_VH', element: 'OverallStatus' } }]  
      @Consumption.filter.defaultValue: 'O'    
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized, 
      

      LocalLastChangedAt,
      /* Associations */
      _Agency,
      _Booking : redirected to composition child YC_Booking_A_D,
      _Currency,
      _OverallStatus, 
      _Customer
}
