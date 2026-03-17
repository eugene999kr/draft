CLASS lhc_YR_BookingSupplement_D DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR YR_BookingSupplement_D~calculateTotalPrice.

    METHODS setBookSupplNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR YR_BookingSupplement_D~setBookSupplNumber.

    METHODS validateSupplement FOR VALIDATE ON SAVE
      IMPORTING keys FOR YR_BookingSupplement_D~validateSupplement.

ENDCLASS.

CLASS lhc_YR_BookingSupplement_D IMPLEMENTATION.

  METHOD calculateTotalPrice.

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_bookingsupplement_d BY \_Travel
    FIELDS ( TravelUUID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    MODIFY ENTITIES OF yr_travel_d IN LOCAL MODE
    ENTITY yr_travel_d
    EXECUTE reCalcTotalPrice
    FROM CORRESPONDING #( lt_travel ).

  ENDMETHOD.

  METHOD setBookSupplNumber.
    DATA lv_max_booksupplid    TYPE /dmo/booking_supplement_id.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lt_bookingsupl_update TYPE TABLE FOR UPDATE yr_travel_d\\YR_BookingSupplement_D.

    " 현재 bookingsuppl로 rba booking을 읽겠다.
    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_bookingsupplement_d BY \_Booking
         FIELDS ( BookingUUID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_booking).

    " 상위의 booking를 읽고, 지금 작업중인 booksuppl이 아니라 상위 booking의 bookingsuppl을 다시 읽는다
    " 이것은 작업중인 상태에서 table로 이미 여러 bookingsuppl이 다른 사용자에 의해 존재 할 수 있으므로
    " 작업중인 booksuppl이 아니라 parent의 child를 전체적으로 다시 읽어오는 것이다.

    LOOP AT lt_booking INTO DATA(ls_booking).

      " 바로 위에서 읽어온 booking으로 booksuppl을 읽겠다. 조건은 위애서 읽은 booking-%tky
      READ ENTITIES OF yr_travel_d IN LOCAL MODE
           ENTITY yr_booking_d BY \_BookingSupplement
           FIELDS ( BookingSupplementID )
           WITH VALUE #( ( %tky = ls_booking-%tky ) )
           RESULT DATA(lt_bookingsupl).

      lv_max_booksupplid = '00'.
      LOOP AT lt_bookingsupl INTO DATA(ls_bookingsuppl).
        IF ls_bookingsuppl-BookingSupplementID > lv_max_booksupplid.
          lv_max_booksupplid = ls_bookingsuppl-BookingSupplementID.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_bookingsupl INTO ls_bookingsuppl WHERE BookingSupplementID IS INITIAL.
        lv_max_booksupplid += 1.

        APPEND VALUE #( %tky                = ls_bookingsuppl-%tky
                        BookingSupplementID = lv_max_booksupplid )
               TO lt_bookingsupl_update.

      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD validateSupplement.
    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_bookingsupplement_d
         FIELDS ( SupplementID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_bookingsuppl)
         FAILED DATA(lt_read_fail).

    failed = CORRESPONDING #( DEEP lt_read_fail ).

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_bookingsupplement_d BY \_Booking
         FROM CORRESPONDING #( lt_bookingsuppl )
         LINK DATA(lt_booksuppl_booking_link).

    READ ENTITIES OF yr_travel_d IN LOCAL MODE
         ENTITY yr_bookingsupplement_d BY \_Travel
         FROM CORRESPONDING #( lt_bookingsuppl )
         LINK DATA(lt_booksuppl_travel_link).

    DATA lt_supplement TYPE SORTED TABLE OF /dmo/supplement WITH UNIQUE KEY supplement_id.

    lt_supplement = CORRESPONDING #( lt_bookingsuppl DISCARDING DUPLICATES MAPPING supplement_id = SupplementID ).
    DELETE lt_supplement WHERE supplement_id IS INITIAL.

    IF lt_supplement IS NOT INITIAL.
      SELECT FROM /dmo/supplement
        FIELDS supplement_id
        FOR ALL ENTRIES IN @lt_supplement
        WHERE supplement_id = @lt_supplement-supplement_id
        INTO TABLE @DATA(lt_valid_suppl).

    ENDIF.

    " 여기 bookingsupp에서 path 즉 reported-yr_bookingsupplement_d-path는
    " yr_travel_d-traveluuid, yr_booking_d-bookinguuid이다. 즉 각각 %tky로 표한힐 수 있다.

    LOOP AT lt_bookingsuppl ASSIGNING FIELD-SYMBOL(<ls_booksuppl>).

      APPEND VALUE #( %tky        = <ls_booksuppl>-%tky
                      %state_area = 'Validate_Supplement' )
             TO reported-yr_bookingsupplement_d.

      IF <ls_booksuppl>-SupplementID IS INITIAL.

        APPEND VALUE #( %tky = <ls_booksuppl>-%tky ) TO failed-yr_bookingsupplement_d.

        APPEND VALUE #(
            %tky        = <ls_booksuppl>-%tky
            %state_area = 'Validate_Supplement'
            %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>supplement_unknown
                                                       severity = if_abap_behv_message=>severity-error )
            %path       = VALUE #(
                yr_travel_d-%tky  = lt_booksuppl_travel_link[ KEY id
                                                              source-%tky = <ls_booksuppl>-%tky ]-target-%tky
                yr_booking_d-%tky = lt_booksuppl_booking_link[ KEY id
                                                               source-%tky = <ls_booksuppl>-%tky ]-target-%tky ) )
               TO reported-yr_bookingsupplement_d.

      ELSEIF         <ls_booksuppl>-SupplementID IS NOT INITIAL
             AND NOT line_exists( lt_valid_suppl[ supplement_id = <ls_booksuppl>-SupplementID ] ).

        APPEND VALUE #( %tky = <ls_booksuppl>-%tky ) TO failed-yr_bookingsupplement_d.

        APPEND VALUE #(
            %tky        = <ls_booksuppl>-%tky
            %state_area = 'Validate_Supplement'
            %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>supplement_unknown
                                                       severity = if_abap_behv_message=>severity-error )
            %path       = VALUE #(
                yr_travel_d-%tky  = lt_booksuppl_travel_link[ KEY id
                                                              source-%tky = <ls_booksuppl>-%tky ]-target-%tky
                yr_booking_d-%tky = lt_booksuppl_booking_link[ KEY id
                                                               source-%tky = <ls_booksuppl>-%tky ]-target-%tky ) )

               TO reported-yr_bookingsupplement_d.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

































ENDCLASS.
