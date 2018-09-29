// There's no babel or webpack build process in this thing, so this will only work on
// the most modern of browsers which support ES2015 class syntax.
class Clearbit {
  constructor(plaid, plaidEnv, plaidPublicKey) {
    this.handler = plaid.create({
      apiVersion: "v2",
      clientName: "Coding Challenge",
      env: plaidEnv,
      product: ["transactions"],
      key: plaidPublicKey,
      onSuccess: public_token => {
        this.saveToken(public_token);
      }
    });

    $("#link-btn").on("click", _e => {
      this.openModal();
    });
  }

  openModal() {
    this.handler.open();
  }

  saveToken(public_token) {
    $.post(
      "/access_token",
      {
        public_token: public_token
      },
      data => {
        $("#container").fadeOut("fast", () => {
          $("#item_id").text(data.item_id);
          $("#access_token").text(data.access_token);
          $("#intro").hide();
          $("#app, #steps").fadeIn("slow");
        });
        this.getTransactions();
      }
    );
  }

  getTransactions() {
    $.ajax("/transactions", {
      success: (data, _textStatus, _jqXHR) => {
        this.renderTransactions(data.transactions);
        this.deleteToken();
      },
      error: (jqXHR, _textStatus, _errorThrown) => {
        const data = jqXHR.responseJSON;
        if (data.error != null && data.error.error_code != null) {
          this.renderError(data.error);
        }
      }
    });
  }

  renderTransactions(transactions) {
    const $component = $("#get-transactions-data");
    const defaultLogoColors = ["blue", "red", "green", "purple", "black"];
    let html = `<tr>
                  <td></td>
                  <td><strong>Name</strong></td>
                  <td><strong>Amount</strong></td>
                  <td><strong>Date</strong></td>
                </tr>`;

    transactions.forEach((txn, idx) => {
      const color = defaultLogoColors[idx % defaultLogoColors.length];
      const letter = txn.name[0].toUpperCase();
      html += `<tr data-index="${idx}">
                 <td class="logo" style="background-color: ${color};">${letter}</td>
                 <td class="name">${
                   txn.name
                 } <span class="domain"></span> <span class="recurring">${
        txn.recurring ? "&#x267a; RECURRING" : ""
      }</span></td>
                 <td class="amount">$${txn.amount.toFixed(2)}</td>
                 <td class="date">${txn.date}</td>
               </tr>`;
      this.getCompanyDetail(txn.name, idx);
    });
    $component.html(html);
  }

  getCompanyDetail(name, idx) {
    $.get("/company/" + encodeURIComponent(name), data => {
      if (data !== null && data.logo && data.domain) {
        this.renderCompanyDetail(idx, data.logo, data.domain);
      }
    });
  }

  deleteToken() {
    $.ajax("/access_token", {
      type: "DELETE",
      error: (jqXHR, _textStatus, _errorThrown) => {
        const data = jqXHR.responseJSON;
        if (data.error != null && data.error.error_code != null) {
          this.renderError(data.error);
        }
      }
    });
  }

  renderCompanyDetail(idx, logo, domain) {
    const $row = $("#get-transactions-data").find(`tr[data-index=${idx}]`);
    const $logo = $row.find("td.logo");
    $logo.html(`<img src="${logo}"/>`);
    const $domain = $row.find("span.domain");
    $domain.html(`<a href="http://${domain}" target="_blank">${domain}</a>`);
  }

  renderError(error) {
    const $component = $("#get-transactions-data");

    // Format the error
    var errorHtml =
      '<div class="inner"><p>' +
      "<strong>" +
      error.error_code +
      ":</strong> " +
      (error.display_message == null
        ? error.error_message
        : error.display_message) +
      "</p></div>";

    if (error.error_code === "PRODUCT_NOT_READY") {
      // Add additional context for `PRODUCT_NOT_READY` errors
      errorHtml +=
        '<div class="inner"><p>Note: The PRODUCT_NOT_READY ' +
        "error is returned when a request to retrieve Transaction data " +
        'is made before Plaid finishes the <a href="https://plaid.com/' +
        'docs/quickstart/#transaction-data-with-webhooks">initial ' +
        "transaction pull.</a></p></div>";
    }

    // Render the error
    $component.html(errorHtml).slideDown();
  }
}

if (typeof module !== "undefined") {
  module.exports = Clearbit;
}
