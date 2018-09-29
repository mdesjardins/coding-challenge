const Plaid = require("./__mocks__/Plaid.js");
const Clearbit = require("../static/app.js");

jest.mock("./__mocks__/Plaid.js");

let clearbit;
beforeEach(() => {
  document.body.innerHTML = `<div>
                               <button id="link-btn" />
                             </div>`;
  clearbit = new Clearbit(Plaid, "env", "publicKey");
});

describe("constructor", () => {
  test("invokes the create method of the Plaid client", () => {
    expect(Plaid.create).toHaveBeenCalled();
  });

  test("assigns an onclick handler to the link-btn", () => {
    clearbit.openModal = jest.fn();
    $("#link-btn").click();
    expect(clearbit.openModal).toHaveBeenCalled();
  });
});

describe("saveToken", () => {
  test("posts token to the server", () => {
    $.post = jest.fn();
    clearbit.saveToken("a_token");
    expect($.post).toHaveBeenCalledWith(
      "/access_token",
      { public_token: "a_token" },
      expect.any(Function)
    );
  });
});

describe("getTransactions", () => {
  test("gets from the server", () => {
    $.ajax = jest.fn();
    clearbit.getTransactions();
    expect($.ajax).toHaveBeenCalledWith("/transactions", {
      success: expect.any(Function),
      error: expect.any(Function)
    });
  });
});

describe("deleteToken", () => {
  test("sends a DELETE /access_token to the server", () => {
    $.ajax = jest.fn();
    clearbit.deleteToken();
    expect($.ajax).toHaveBeenCalledWith("/access_token", {
      type: "DELETE",
      error: expect.any(Function)
    });
  });
});

describe("renderTransactions", () => {
  const transactions = [
    {
      name: "Elvis",
      amount: 123,
      date: "2018-01-01"
    },
    { name: "Priscilla", amount: 456, date: "2017-01-01" }
  ];

  beforeEach(() => {
    document.body.innerHTML = '<table id="get-transactions-data" />';
  });

  test("renders one header row plus one row per transaction", () => {
    clearbit.renderTransactions(transactions);
    expect($("tr").length).toBe(1 + transactions.length);
  });

  test("renders a data-index attribute on each row", () => {
    clearbit.renderTransactions(transactions);
    expect($("tr[data-index=0]").length).toBe(1);
    expect($("tr[data-index=1]").length).toBe(1);
  });

  describe("data row contents", () => {
    let $dataRows;
    beforeEach(() => {
      clearbit.getCompanyDetail = jest.fn();
      clearbit.renderTransactions(transactions);
      $dataRows = $("tr[data-index]");
    });

    test("sets background colors on the logo column", () => {
      expect($($dataRows[0]).find("td.logo")[0].style.backgroundColor).toEqual(
        "blue"
      );
      expect($($dataRows[1]).find("td.logo")[0].style.backgroundColor).toEqual(
        "red"
      );
    });

    test("sets the letter in the logo column", () => {
      expect($($dataRows[0]).find("td.logo")[0].innerHTML).toEqual("E");
      expect($($dataRows[1]).find("td.logo")[0].innerHTML).toEqual("P");
    });

    test("sets the name column", () => {
      expect($($dataRows[0]).find("td.name")[0].innerHTML).toMatch(/Elvis/);
      expect($($dataRows[1]).find("td.name")[0].innerHTML).toMatch(/Priscilla/);
    });

    test("the name column contains a span for populating the domain", () => {
      expect($($dataRows[0]).find("td.name")[0].innerHTML).toMatch(
        /<span class="domain"><\/span>/
      );
      expect($($dataRows[1]).find("td.name")[0].innerHTML).toMatch(
        /<span class="domain"><\/span>/
      );
    });

    test("renders the amount and formats it nicely", () => {
      expect($($dataRows[0]).find("td.amount")[0].innerHTML).toEqual("$123.00");
      expect($($dataRows[1]).find("td.amount")[0].innerHTML).toEqual("$456.00");
    });

    test("renders the date", () => {
      expect($($dataRows[0]).find("td.date")[0].innerHTML).toEqual(
        "2018-01-01"
      );
      expect($($dataRows[1]).find("td.date")[0].innerHTML).toEqual(
        "2017-01-01"
      );
    });

    test("invokes getCompanyDetail once per row", () => {
      expect(clearbit.getCompanyDetail).toHaveBeenCalledTimes(2);
      expect(clearbit.getCompanyDetail).toHaveBeenLastCalledWith(
        "Priscilla",
        1
      );
    });
  });
});

describe("getCompanyDetail", () => {
  test("gets company data from the server", () => {
    $.get = jest.fn();
    clearbit.getCompanyDetail("Elvis", 0);
    expect($.get).toHaveBeenCalledWith("/company/Elvis", expect.any(Function));
  });
});

describe("renderCompanyDetail", () => {
  beforeEach(() => {
    document.body.innerHTML = `<table id="get-transactions-data">
                                 <tr data-index="0">
                                   <td class="logo"/>
                                   <td class="name">
                                     <span class="domain"/>
                                   </td>
                                 </tr>
                               </table>`;
  });

  test("it updates the logo", () => {
    clearbit.renderCompanyDetail(0, "elvis.png", "http://www.example.com");
    expect($("td.logo img").length).toBe(1);
    expect($("td.logo img").attr("src")).toBe("elvis.png");
  });

  test("it updates the domain", () => {
    clearbit.renderCompanyDetail(0, "elvis.png", "www.example.com");
    expect($("td.name span.domain a").html()).toBe("www.example.com");
    expect($("td.name span.domain a").attr("href")).toBe(
      "http://www.example.com"
    );
  });
});

describe("renderError", () => {
  beforeEach(() => {
    document.body.innerHTML = `<table id="get-transactions-data">`;
  });

  describe("when there is a display_message", () => {
    test("renders the error message and error_code", () => {
      clearbit.renderError({
        error_code: "123",
        display_message: "Elvis is dead.",
        error_message: "Blue suede shoes."
      });
      expect($(".inner strong").html()).toMatch(/123/);
      expect($(".inner").html()).toMatch(/Elvis is dead/);
      expect($(".inner").html()).not.toMatch(/Blue suede shoes/);
    });
  });

  describe("when there is no display_message", () => {
    test("renders the error message and error_code", () => {
      clearbit.renderError({
        error_code: "123",
        error_message: "Elvis is dead."
      });
      expect($(".inner strong").html()).toMatch(/123/);
      expect($(".inner").html()).toMatch(/Elvis is dead/);
    });
  });

  describe("when the error_code is PRODUCT_NOT_READY", () => {
    test("renders some additional stuff", () => {
      clearbit.renderError({
        error_code: "PRODUCT_NOT_READY",
        error_message: "Elvis is dead."
      });

      // ick - kinda fragile.
      expect($(".inner:nth-child(2)").html()).toMatch(
        /Note: The PRODUCT_NOT_READY/
      );
    });
  });
});
