CLASS lhc_YR_TRAVEL_D DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR yr_travel_d RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR yr_travel_d RESULT result.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE yr_travel_d.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE yr_travel_d.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~accepttravel RESULT result.

    METHODS deductdiscount FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~deductdiscount RESULT result.

    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~recalctotalprice.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~rejecttravel RESULT result.
    METHODS calctotprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR yr_travel_d~calctotprice.

    METHODS setstatusopen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR yr_travel_d~setstatusopen.

    METHODS settravelid FOR DETERMINE ON SAVE
      IMPORTING keys FOR yr_travel_d~settravelid.

    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR yr_travel_d~validatecustomer.
    METHODS activate FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~activate.

    METHODS discard FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~discard.

    METHODS edit FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~edit.

    METHODS resume FOR MODIFY
      IMPORTING keys FOR ACTION yr_travel_d~resume.

ENDCLASS.

CLASS lhc_YR_TRAVEL_D IMPLEMENTATION.

  METHOD get_instance_authorizations.
    DATA: lv_update TYPE abp_behv_auth.
    DATA: lv_delete TYPE abp_behv_auth.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    FIELDS ( AgencyID ) "field에 agencyid만 넣더라도 key값을 읽어온다.
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels)
    FAILED failed.

    CHECK lt_travels IS NOT INITIAL.

    SELECT FROM /dmo/a_travel_d AS a
      JOIN /dmo/agency AS b
      ON a~agency_id = b~agency_id
      FIELDS a~travel_uuid, a~agency_id, b~country_code
      FOR ALL ENTRIES IN @lt_travels
      WHERE a~travel_uuid = @lt_travels-TravelUUID
       INTO TABLE @DATA(lt_age_crty).
*
    LOOP AT lt_travels INTO DATA(ls_travels).

      READ TABLE lt_age_crty ASSIGNING FIELD-SYMBOL(<ls_age_ctry>)
                    WITH KEY travel_uuid = ls_travels-TravelUUID.

      IF sy-subrc IS INITIAL.
        IF requested_authorizations-%update = if_abap_behv=>mk-on.

*          AUTHORITY-CHECK OBJECT '/DMO/TRVL'
*             ID '/DMO/TRVL' FIELD <ls_age_ctry>-country_code
*             ID 'ACTVT' FIELD '02'.

*          APPEND VALUE #( TravelUUID = ls_travels-TravelUUID
*                          %update = COND #(  WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
*                                                               ELSE if_abap_behv=>auth-unauthorized )
*                   ) TO result.

          lv_update = COND #(  WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                                 ELSE if_abap_behv=>auth-unauthorized ).
          APPEND VALUE #( %tky = ls_travels-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                     agency_id = ls_travels-AgencyID
                                     severity = if_abap_behv_message=>severity-error  )
                          %element-agencyid = if_abap_behv=>mk-on
           ) TO reported-yr_travel_d.

        ENDIF.

        IF requested_authorizations-%delete = if_abap_behv=>mk-on.

*          AUTHORITY-CHECK OBJECT '/DMO/TRVL'
*             ID '/DMO/TRVL' FIELD <ls_age_ctry>-country_code
*             ID 'ACTVT' FIELD '06'.

*          APPEND VALUE #( TravelUUID = ls_travels-TravelUUID
*                          %delete = COND #(  WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
*                                                               ELSE if_abap_behv=>auth-unauthorized )
*                   ) TO result.

          lv_delete = COND #(  WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                                 ELSE if_abap_behv=>auth-unauthorized ).
          APPEND VALUE #( %tky = ls_travels-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                     agency_id = ls_travels-AgencyID
                                     severity = if_abap_behv_message=>severity-error  )
                          %element-agencyid = if_abap_behv=>mk-on
           ) TO reported-yr_travel_d.

        ENDIF.

      ENDIF.

      APPEND VALUE #( TravelUUID = ls_travels-TravelUUID
                      %update = lv_update
                      %delete = lv_delete
                      ) TO result.


    ENDLOOP.


  ENDMETHOD.

  METHOD get_global_authorizations.

    IF requested_authorizations-%create = if_abap_behv=>mk-on.

      AUTHORITY-CHECK OBJECT '/DMO/TRVL'
      ID '/DMO/TRVL' DUMMY
      ID 'ACTVT' FIELD '01'.

      result-%create = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                                 ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.

      AUTHORITY-CHECK OBJECT '/DMO/TRVL'
      ID '/DMO/TRVL' DUMMY
      ID 'ACTVT' FIELD '02'.

      result-%update = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                                 ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.

      AUTHORITY-CHECK OBJECT '/DMO/TRVL'
      ID '/DMO/TRVL' DUMMY
      ID 'ACTVT' FIELD '06'.

      result-%delete = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                                 ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

  ENDMETHOD.

  METHOD precheck_create.
    DATA:lt_agency TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    lt_agency = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).

    CHECK lt_agency IS NOT INITIAL.

    SELECT FROM /dmo/agency
    FIELDS agency_id, country_code
    FOR ALL ENTRIES IN @lt_agency
    WHERE agency_id = @lt_agency-agency_id
    INTO TABLE @DATA(lt_ag_ct).

    IF sy-subrc IS INITIAL.

      LOOP AT entities INTO DATA(ls_entity).

        READ TABLE lt_ag_ct ASSIGNING FIELD-SYMBOL(<ls_age_ctry>)
        WITH KEY agency_id = ls_entity-AgencyID.

        AUTHORITY-CHECK OBJECT '/DMO/TRVL'
           ID '/DMO/CNTRY' FIELD <ls_age_ctry>-country_code
          ID 'ACTVT' FIELD '01'.

*        IF sy-subrc IS NOT INITIAL.
*
*          failed-yr_travel_d = VALUE #( ( %tky = ls_entity-%tky ) ).
*
*          APPEND VALUE #( %tky = ls_entity-%tky
*                          %msg = NEW /dmo/cm_flight_messages(
*                                                     textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
*                                                     agency_id = ls_entity-AgencyID
*                                                     severity  = if_abap_behv_message=>severity-error )
*                           %element-AgencyID = if_abap_behv=>mk-on
*            ) TO reported-yr_travel_d.
*
*        ENDIF.


      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD precheck_update.

    DATA:lt_agency TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    lt_agency = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).

    CHECK lt_agency IS NOT INITIAL.

    SELECT FROM /dmo/agency
    FIELDS agency_id, country_code
    FOR ALL ENTRIES IN @lt_agency
    WHERE agency_id = @lt_agency-agency_id
    INTO TABLE @DATA(lt_ag_ct).

    IF sy-subrc IS INITIAL.

      LOOP AT entities INTO DATA(ls_entity).

        READ TABLE lt_ag_ct ASSIGNING FIELD-SYMBOL(<ls_age_ctry>)
        WITH KEY agency_id = ls_entity-AgencyID.

        AUTHORITY-CHECK OBJECT '/DMO/TRVL'
           ID '/DMO/CNTRY' FIELD <ls_age_ctry>-country_code
          ID 'ACTVT' FIELD '02'.

*        IF sy-subrc IS NOT INITIAL.
*
*          failed-yr_travel_d = VALUE #( ( %tky = ls_entity-%tky ) ).
*
*          APPEND VALUE #( %tky = ls_entity-%tky
*                          %msg = NEW /dmo/cm_flight_messages(
*                                                     textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
*                                                     agency_id = ls_entity-AgencyID
*                                                     severity  = if_abap_behv_message=>severity-error )
*                           %element-AgencyID = if_abap_behv=>mk-on
*            ) TO reported-yr_travel_d.
*
*        ENDIF.


      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                    OverallStatus = 'A' ) ).

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

    result = VALUE #( FOR ls_travel IN lt_travels ( %tky = ls_travel-%tky
                                                    %param = ls_travel ) ).



  ENDMETHOD.

  METHOD deductDiscount.
    DATA lv_disc       TYPE decfloat16.
    DATA lt_travel_new TYPE TABLE FOR UPDATE yr_travel_d.

    DATA(lt_keys) = keys.

    LOOP AT lt_keys ASSIGNING FIELD-SYMBOL(<ls_keys>) WHERE    %param-discount IS INITIAL
                                                            OR %param-discount  > 100
                                                            OR %param-discount <= 0.
      APPEND VALUE #( %tky = <ls_keys>-%tky ) TO failed-yr_travel_d.

      APPEND VALUE #( %tky                   = <ls_keys>-%tky
                      %msg                   = NEW /dmo/cm_flight_messages(
                                                       textid   = /dmo/cm_flight_messages=>discount_invalid
                                                       severity = if_abap_behv_message=>severity-error )
                      %element-bookingfee    = if_abap_behv=>mk-on
                      %action-deductdiscount = if_abap_behv=>mk-on )
             TO reported-yr_travel_d.

      DELETE lt_keys.

    ENDLOOP.

    IF lt_keys IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_travel_d
         FIELDS ( BookingFee )
         WITH CORRESPONDING #( lt_keys )
         RESULT DATA(lt_travel).

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      DATA(lv_discount) = lt_keys[ KEY id
                                   %tky = <ls_travel>-%tky ]-%param-discount.
      lv_disc = lv_discount / 100.
      DATA(lv_disc_book_fee) = <ls_travel>-BookingFee - ( <ls_travel>-BookingFee * lv_disc ).

      APPEND VALUE #( %tky       = <ls_travel>-%tky
                      bookingfee = lv_disc_book_fee ) TO lt_travel_new.

    ENDLOOP.
* deduct discount를 실행해서 여기 yr_travel_d를 modify 하면 determination에 지정한 조건이 충족되어(on modify field bookingfee) calcTotPrice 가 호출된다.
    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
           ENTITY yr_travel_d
           UPDATE FIELDS ( BookingFee )
           WITH lt_travel_new.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_travel_d
         ALL FIELDS WITH CORRESPONDING #( lt_keys )
         RESULT DATA(lt_modified_travel).

    result = VALUE #( FOR ls_mo_travel IN lt_modified_travel
                      ( %tky   = ls_mo_travel-%tky
                        %param = ls_mo_travel ) ).
  ENDMETHOD.

  METHOD reCalcTotalPrice.

    TYPES:BEGIN OF ty_amount_per_currencycode,
            amount        TYPE /dmo/total_price,
            currency_code TYPE /dmo/currency_code,
          END OF ty_AMOUNT_PER_CURRENCYCODE.

    DATA:lt_amt_per_ccode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    FIELDS ( BookingFee CurrencyCode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

    DELETE lt_travels WHERE CurrencyCode IS INITIAL.

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<ls_travel>).

      lt_amt_per_ccode = VALUE #( (  amount = <ls_travel>-BookingFee
                                   currency_code = <ls_travel>-CurrencyCode ) ).
      READ ENTITIES OF yr_travel_d IN LOCAL MODE
      ENTITY yr_travel_d BY \_Booking
      FIELDS ( FlightPrice CurrencyCode )
      WITH VALUE #( ( %tky = <ls_travel>-%tky ) )
      RESULT DATA(lt_booking) .

      LOOP AT lt_booking INTO DATA(ls_booking) WHERE CurrencyCode IS NOT INITIAL.

        COLLECT VALUE ty_amount_per_currencycode( amount = ls_booking-FlightPrice
                                                  currency_code = ls_booking-CurrencyCode )
                                                  INTO lt_amt_per_ccode.
      ENDLOOP.

      READ ENTITIES OF yr_travel_d IN LOCAL MODE
      ENTITY yr_booking_d BY \_BookingSupplement
      FIELDS ( BookSupplPrice CurrencyCode )
      WITH VALUE #( FOR rba_booking IN lt_booking ( %tky = rba_booking-%tky )  )
      RESULT DATA(lt_bookingsupplements).

      LOOP AT lt_bookingsupplements INTO DATA(ls_booksuppl) WHERE CurrencyCode IS NOT INITIAL.

        COLLECT VALUE ty_amount_per_currencycode( amount = ls_booksuppl-BookSupplPrice
                                                  currency_code = ls_booksuppl-CurrencyCode  ) INTO lt_amt_per_ccode.
      ENDLOOP.

      CLEAR <ls_travel>-TotalPrice.
      LOOP AT lt_amt_per_ccode INTO DATA(ls_amt).
        IF ls_amt-currency_code = <ls_travel>-CurrencyCode.
          <ls_travel>-TotalPrice += ls_amt-amount.
        ELSE.

          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING
              iv_amount               = ls_amt-amount
              iv_currency_code_source = ls_amt-currency_code
              iv_currency_code_target =  <ls_travel>-CurrencyCode
              iv_exchange_rate_date   =  cl_abap_context_info=>get_system_date( )
            IMPORTING
              ev_amount               = DATA(lv_price)
          ).

          <ls_travel>-TotalPrice += lv_price.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #( lt_travels ).


  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                    OverallStatus = 'X' ) ).

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

    result = VALUE #( FOR ls_travel IN lt_travels ( %tky = ls_travel-%tky
                                                    %param = ls_travel ) ).

  ENDMETHOD.

  METHOD calcTotPrice.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    EXECUTE reCalcTotalPrice
    FROM CORRESPONDING #( keys ).


  ENDMETHOD.

  METHOD setStatusOpen.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    DELETE lt_travel WHERE OverallStatus IS NOT INITIAL.

    CHECK lt_travel IS NOT INITIAL.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_travel IN lt_travel ( %tky = ls_travel-%tky
                                               OverallStatus = 'O' ) ).

  ENDMETHOD.

  METHOD setTravelId.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    FIELDS ( TravelID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    DELETE lt_travel WHERE TravelID IS NOT INITIAL.

    CHECK lt_travel IS NOT INITIAL.

    SELECT FROM /dmo/a_travel_d
    FIELDS MAX( travel_id )
    INTO @DATA(lv_max_travelid).

* update에 필드 travelid를 지정했는데, with value로 처리하려면, travelid만 넣어주는게 아니라
* eml처리를 위한 기본으로 %tky가 있다. 위에서 read해온 lt_travel에도 %tky가 있다.


    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    UPDATE FIELDS ( TravelID )
    WITH VALUE #( FOR ls_travel IN lt_travel INDEX INTO lv_index (  %tky = ls_travel-%tky
                                                                    TravelID = lv_max_travelid + lv_index
                 ) ).


  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    FIELDS ( CustomerID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    DATA:lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    lt_customer = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).

    DELETE lt_customer WHERE customer_id IS INITIAL.

    IF lt_customer IS NOT INITIAL.
      SELECT FROM /dmo/customer
      FIELDS customer_id
      FOR ALL ENTRIES IN @lt_customer
      WHERE customer_id = @lt_customer-customer_id
      INTO TABLE @DATA(lt_valid_customer).
    ENDIF.

    LOOP AT lt_travel INTO DATA(ls_travel).

      APPEND VALUE #( %tky = ls_travel-%tky
                      %state_area = 'Validate_customer' ) TO reported-yr_travel_d.

      IF ls_travel-CustomerID IS INITIAL.

      ELSEIF ls_travel-CustomerID IS NOT INITIAL AND
      NOT line_exists( lt_valid_customer[ customer_id = ls_travel-CustomerID ] ).

        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-yr_travel_d.

        APPEND VALUE #( %tky = ls_travel-%tky
                        %state_area = 'Validate_customer'
                        %msg = NEW /dmo/cm_flight_messages(
                                  textid         = /dmo/cm_flight_messages=>customer_unkown
                                  customer_id    = ls_travel-CustomerID
                                  severity       = if_abap_behv_message=>severity-error
        )
                         %element-customerid = if_abap_behv=>mk-on
        ) TO reported-yr_travel_d.


      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD Activate.
  ENDMETHOD.

  METHOD Discard.
  ENDMETHOD.

  METHOD Edit.
  ENDMETHOD.

  METHOD Resume.
  ENDMETHOD.

ENDCLASS.
