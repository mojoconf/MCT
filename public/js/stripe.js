;(function($) {
  var stripeHandler;

  var cardIcon = function(e) {
    var $i = $(this).closest('div').find('i:first');
    var card = 'cc-' + ($.payment.cardType(this.value) || 'unknown');
    if (card != 'cc-visa' && card != 'cc-mastercard' && card != 'cc-amex') card = 'credit-card';
    $i.attr('class', 'fa fa-' + card);
  };

  var resetValidation = function() {
    $(this).removeClass('field-with-error');
  };

  var stripeButtonClicked = function(e) {
    var $target = $(e.target);
    var $stripeForm = $('.stripe-payment-form');
    var $registerBeforeCheckout = $('.register-before-checkout');
    var totalAmount = 0;
    var productId = [];
    var $buttons;

    e.preventDefault();

    // payment in progress
    if ($stripeForm.find('button[disabled]').length) return;

    if ($registerBeforeCheckout.length) {
      $registerBeforeCheckout.removeClass('hidden');
      $target.closest('table').find('a.custom-stripe-button').addClass('pure-button-disabled');
      return;
    }

    $target.toggleClass('pure-button-active');
    $buttons = $target.closest('table').find('a.custom-stripe-button.pure-button-active');
    $buttons.each(function() {
      productId.push($(this).attr('data-product-id'));
      totalAmount += parseInt($(this).attr('data-amount'));
    });

    if (window.DEBUG) console.log(totalAmount, productId, $buttons);

    $stripeForm.find('.cc-amount').attr('value', (totalAmount / 100).toFixed(2) + ' ' + $stripeForm.find('input[name="currency"]').val());
    $stripeForm.find('input[name="amount"]').attr('value', totalAmount);
    $stripeForm.find('input[name="product_id"]').attr('value', productId.join(','));

    // no selected products
    if (!$buttons.length) return;

    $stripeForm.removeClass('hidden').find('.cc-card').focus();
    $stripeForm.submit(function(e) {
      e.preventDefault();
      validateStripeForm($stripeForm);
      if ($stripeForm.find('.field-with-error').length) return;
      $stripeForm.find('.error').addClass('hidden');
      $stripeForm.find('button').prop('disabled', true).text('Processing...');
      Stripe.setPublishableKey($stripeForm.find('.cc-key').val());
      Stripe.card.createToken($stripeForm, function(status, response) {
        if (response.error) {
          $stripeForm.find('.error').text(response.error.message).removeClass('hidden');
          $stripeForm.find('button').prop('disabled', false).text('Buy');
        }
        else {
          $stripeForm.find('[name="stripeToken"]').attr('value', response.id);
          $stripeForm.find('form').get(0).submit();
        }
      });
    });
  };

  var validateStripeForm = function($form) {
    var $card = $('input.cc-card', $form);
    var $exp = $('input.cc-exp-month, input.cc-exp-year', $form);
    var $cvc = $('input.cc-cvc', $form);
    var m;

    m = $.payment.validateCardNumber($card.val()) ? 'removeClass' : 'addClass';
    $card[m]('field-with-error');

    m = $.payment.validateCardExpiry($exp.eq(0).val(), $exp.eq(1).val()) ? 'removeClass' : 'addClass';
    $exp[m]('field-with-error');

    m = $.payment.validateCardCVC($cvc.val(), $.payment.cardType($card.val())) ? 'removeClass' : 'addClass';
    $cvc[m]('field-with-error');
  };

  $(document).ready(function() {
    $('.custom-stripe-button').click(stripeButtonClicked);
    $('input.cc-card').payment('formatCardNumber').keyup(cardIcon).focus(resetValidation);
    $('input.cc-exp-month').payment('restrictNumeric').focus(resetValidation);
    $('input.cc-exp-year').payment('restrictNumeric').focus(resetValidation);
    $('input.cc-cvc').payment('formatCardCVC').focus(resetValidation);
  });
})(jQuery);
