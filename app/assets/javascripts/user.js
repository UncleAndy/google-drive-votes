
$( document ).ready(function() {
  function calc_idhash() {
    var source_str = $.trim($("#last_name").val()) + ':' + $.trim($("#first_name").val()) + ':' + $.trim($("#middle_name").val()) + ':' + $.trim($("#birth_date").val());
    source_str = source_str.toUpperCase()
    return(CryptoJS.SHA512(source_str));
  };

  $("#idhash_form").submit(function() {
    $("#idhash_field").val(calc_idhash());
    return(true);
  })
});
