CLASS lhc_yr_booking_d DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR yr_booking_d~calculateTotalPrice.

    METHODS setBookingDate FOR DETERMINE ON SAVE
      IMPORTING keys FOR yr_booking_d~setBookingDate.

    METHODS setBookingNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR yr_booking_d~setBookingNumber.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR yr_booking_d~validateCustomer.

ENDCLASS.

CLASS lhc_yr_booking_d IMPLEMENTATION.

  METHOD calculateTotalPrice.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_booking_d BY \_Travel
    FIELDS ( TravelUUID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    EXECUTE reCalcTotalPrice
    FROM CORRESPONDING #( lt_travel ).


  ENDMETHOD.

  METHOD setBookingDate.
    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_booking_d
    FIELDS ( BookingDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_booking).

    DELETE lt_booking WHERE BookingDate IS NOT INITIAL.

    CHECK lt_booking IS NOT INITIAL.

    LOOP AT lt_booking ASSIGNING FIELD-SYMBOL(<ls_booking>).

      <ls_booking>-BookingDate = cl_abap_context_info=>get_system_date( ).

    ENDLOOP.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_booking_d
    UPDATE FIELDS ( BookingDate )
    WITH CORRESPONDING #( lt_booking ).


  ENDMETHOD.

  METHOD setBookingNumber.
    DATA: lv_max_bookingid  TYPE /dmo/booking_id,
          lt_booking_update TYPE TABLE FOR UPDATE yr_travel_d\\yr_booking_d.
* 현재 작업중인 booking으로 상위의 travel을 읽고,
    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_booking_d BY \_Travel
    FIELDS ( TravelUUID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    LOOP AT lt_travel INTO DATA(ls_travel).
* 읽어온 상위의 travel로 다시 booking을 읽는다.
* 이것은 현자 작업중인 booking외에도 이전에 booking이 있을 수 있으므로 전체적으로 booking을 다시 읽는것이다.
      READ ENTITIES OF yr_travel_d IN LOCAL MODE
      ENTITY yr_travel_d BY \_Booking
      FIELDS ( BookingID )
      WITH VALUE #( ( %tky = ls_travel-%tky ) ) "with value는 table type이다.
      RESULT DATA(lt_booking).

      lv_max_bookingid = '0000'.
      LOOP AT lt_booking INTO DATA(ls_booking).
        IF ls_booking-BookingID > lv_max_bookingid.
          lv_max_bookingid = ls_booking-BookingID.
        ENDIF.

      ENDLOOP.

      LOOP AT lt_booking INTO ls_booking WHERE BookingID IS INITIAL.
        lv_max_bookingid += 1.
        APPEND VALUE #( %tky = ls_booking-%tky
                        bookingid = lv_max_bookingid ) TO lt_booking_update.

      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_booking_d
    UPDATE FIELDS ( BookingID )
    WITH lt_booking_update.

  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_booking_d
         FIELDS ( CustomerID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_booking).

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_booking_d BY \_Travel
         FROM CORRESPONDING #( lt_booking )
         LINK DATA(lt_travel_booking_link).

    DATA lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    lt_customer = CORRESPONDING #( lt_booking DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE lt_customer WHERE customer_id IS INITIAL.

    IF lt_customer IS NOT INITIAL.
      SELECT FROM /dmo/customer
        FIELDS customer_id
        FOR ALL ENTRIES IN @lt_customer
        WHERE customer_id = @lt_customer-customer_id
        INTO TABLE @DATA(lt_valid_customer).

    ENDIF.

* 여기 booking에서 path는, 즉 reported-yr_booking_d-path 는
* yr_travel_d-traveluuid이다. %tky로 표시할 수도 있다.
    LOOP AT lt_booking INTO DATA(ls_booking).
      APPEND VALUE #( %tky        = ls_booking-%tky
                      %state_area = 'Validate_Customer' ) TO reported-yr_booking_d.

      IF ls_booking-CustomerID IS INITIAL.

        APPEND VALUE #( %tky        = ls_booking-%tky
                        %state_area = 'Validate_Customer'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                   severity = if_abap_behv_message=>severity-error  )
                        %path       = VALUE #(
                            yr_travel_d-%tky = lt_travel_booking_link[ KEY id
                                                                       source-%tky = ls_booking-%tky ]-target-%tky ) )
               TO reported-yr_booking_d.

      ELSEIF         ls_booking-CustomerID IS NOT INITIAL
             AND NOT line_exists( lt_valid_customer[ customer_id = ls_booking-CustomerID ] ).

        APPEND VALUE #( %tky = ls_booking-%tky ) TO failed-yr_booking_d.

        APPEND VALUE #( %tky = ls_booking-%tky
                        %state_area = 'Validate_Customer'
                        %msg = NEW /dmo/cm_flight_messages(
                                             textid        = /dmo/cm_flight_messages=>enter_customer_id
                                             customer_id   = ls_booking-CustomerID
                                             severity      = if_abap_behv_message=>severity-error  )
                        %path = VALUE #( yr_travel_d-%tky = lt_travel_booking_link[ KEY id source-%tky = ls_booking-%tky ]-target-%tky )
         ) TO reported-yr_booking_d.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
