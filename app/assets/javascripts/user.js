
$( document ).ready(function() {
  function calc_idhash() {
    var source_str = $.trim($("#last_name").val()) + ':' + $.trim($("#first_name").val()) + ':' + $.trim($("#middle_name").val()) + ':' + $.trim($("#birth_date").val());
    source_str = source_str.toUpperCase()
    return(CryptoJS.SHA256(source_str).toString(CryptoJS.enc.Hex));
  };

  $("#idhash_form").submit(function() {
    $("#idhash_field").val(calc_idhash());
    return(true);
  });

  $("#new_trust_vote_form").submit(function() {
    if ((typeof($("#new_vote_idhash_field").val()) == "undefined") || ($.trim($("#new_vote_idhash_field").val()).length == 0)) {
      $("#new_vote_idhash_field").val(calc_idhash());
    };
    return(true);
  });

  $("#check_hash").click(function() {
    var idhash_field = $.trim($("#idhash").val()).toUpperCase()
    var idhash_calc = calc_idhash().toUpperCase()
    if (idhash_field == idhash_calc) {
      $("#idhash").css('background-color', '#00cc00');
      $("#result").html("Идентификатор прошел проверку")
    } else {
      $("#idhash").css('background-color', 'red');
      $("#result").html("Идентификатор не соответствует введенным данным")
    };
    return(true);
  });
  
  $( "#slider-range-verify" ).slider({
      range: "min",
      min: -10,
      max: 10,
      value: gon.verify_level,
      slide: function( event, ui ) {
        $( "#verify-level" ).val( ui.value );
      }
  });
  $( "#verify-level" ).val( $( "#slider-range-verify" ).slider( "value" ) );

  $( "#slider-range-trust" ).slider({
      range: "min",
      min: -10,
      max: 10,
      value: gon.trust_level,
      slide: function( event, ui ) {
        $( "#trust-level" ).val( ui.value );
      }
  });
  $( "#trust-level" ).val( $( "#slider-range-trust" ).slider( "value" ) );

  $( "#slider-range-property" ).slider({
      range: "min",
      min: -10,
      max: 10,
      value: gon.property_level,
      slide: function( event, ui ) {
        $( "#property-level" ).val( ui.value );
      }
  });
  $( "#property-level" ).val( $( "#slider-range-property" ).slider( "value" ) );
});
