@EndUserText.label: 'test'
@ClientHandling.algorithm: #SESSION_VARIABLE
@ClientHandling.type: #CLIENT_DEPENDENT
define table function yr_airport_tf  
  //with parameters parameter_name : parameter_type
returns
{
  mandt   : abap.clnt;
  connection : /dmo/connection_id;
  airport : /dmo/airport_id;
  city    : /dmo/city;
  country : land1;

}
implemented by method
  ycl_test=>get_city; 
  