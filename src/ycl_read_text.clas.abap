CLASS ycl_read_text DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_read_text IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~calculate.

    DATA:lv_index TYPE i.
    DATA lt_booking TYPE STANDARD TABLE OF YC_Booking_A_D.
    CHECK it_original_data IS NOT INITIAL.
    lt_booking = CORRESPONDING #( it_original_data ).


    LOOP AT lt_booking ASSIGNING FIELD-SYMBOL(<ls_booking>).
      lv_index += 1.
      CONCATENATE <ls_booking>-ltext 'times' INTO <ls_booking>-ltext.
    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_booking ).

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
  ENDMETHOD.
ENDCLASS.
