codeunit 81006 "LookupValue Inheritance"
{
    Subtype = Test;

    trigger OnRun()
    begin
        //[FEATURE] LookupValue Inheritance
    end;

    var
        Assert: Codeunit "Library Assert";
        LibrarySales: Codeunit "Library - Sales";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        LookupValueCode: Code[10];

    // Instruction NOTES
    // (1) Replacing the argument LookupValueCode in verification call, i.e. [THEN] clause, should make any test fail

    [Test]
    procedure InheritLookupValueFromCustomerOnSalesDocument();
    //[FEATURE] LookupValue Inheritance - Sales Document / Customer
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        //[SCENARIO #0024] Assign customer lookup value to sales document
        Initialize();

        //[GIVEN] Customer with lookup value
        CustomerNo := CreateCustomerWithLookupValue(LookupValueCode);
        //[GIVEN] Sales document (invoice) without a lookup value
        CreateSalesHeader(SalesHeader);

        //[WHEN] Set customer on sales header
        SetCustomerOnSalesHeader(SalesHeader, CustomerNo);

        //[THEN] LookupValue on sales document is populated with lookup value of customer
        VerifyLookupValueOnSalesHeader(SalesHeader, LookupValueCode);
    end;

    [Test]
    procedure CreateCustomerFromContactWithLookupValue()
    //[FEATURE] LookupValue Inheritance - Contact
    var
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerTemplate: Record "Customer Templ.";
    begin
        //[SCENARIO #0026] Check that lookup value is inherited from customer template to customer when creating customer from contact

        //[GIVEN] Customer template with lookup value
        CreateCustomerTemplateWithLookupValue(CustomerTemplate);
        //[GIVEN] Contact
        CreateCompanyContact(Contact);

        //[WHEN] Customer is created from contact
        CreateCustomerFromContact(Contact, CustomerTemplate.Code, Customer);

        //[THEN] Customer has lookup value code field populated with lookup value from customer template
        VerifyLookupValueOnCustomer(Customer."No.", CustomerTemplate."Lookup Value Code");
    end;

    [Test]
    [HandlerFunctions('HandleConfigTemplates')]
    procedure InheritLookupValueFromCustomerTemplateToCustomer();
    //[FEATURE] LookupValue Inheritance - Customer Templates
    var
        CustomerNo: Code[20];
        CustomerTemplateCode: Code[10];
    begin
        //[SCENARIO #0028] Create customer from customer template with lookup value
        Initialize();

        //[GIVEN] Customer template with lookup value
        CustomerTemplateCode := CreateCustomerTemplateWithLookupValue(LookupValueCode);

        //[WHEN] Create customer card
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        CustomerNo := CreateCustomerCard();

        //[THEN] Lookup value on customer is populated with lookup value of customer template
        VerifyLookupValueOnCustomer(CustomerNo, LookupValueCode);
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        //[GIVEN] Lookup value
        LookupValueCode := CreateLookupValueCode();

        isInitialized := true;
        Commit();
    end;

    local procedure CreateLookupValueCode(): Code[10]
    // this smells like duplication ;-) - see test example 1
    var
        LookupValue: Record LookupValue;
    begin
        LookupValue.Init();
        LookupValue.Validate(
            Code,
            LibraryUtility.GenerateRandomCode(LookupValue.FieldNo(Code),
            Database::LookupValue));
        LookupValue.Validate(Description, LookupValue.Code);
        LookupValue.Insert();
        exit(LookupValue.Code);
    end;

    local procedure CreateCustomerWithLookupValue(LookupValueCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Lookup Value Code", LookupValueCode);
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
    end;

    local procedure SetCustomerOnSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify();
    end;

    local procedure CreateCustomerTemplateWithLookupValue(var CustomerTemplate: Record "Customer Templ."): Code[10]
    begin
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Lookup Value Code", CreateLookupValueCode());
        CustomerTemplate.Modify();
        exit(CustomerTemplate."Lookup Value Code");
    end;

    local procedure CreateCompanyContact(var Contact: Record Contact);
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
    end;

    local procedure CreateCustomerFromContact(Contact: Record Contact; CustomerTemplateCode: Code[10]; var Customer: Record Customer);
    begin
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomerFromTemplate(CustomerTemplateCode);
        FindCustomerByCompanyName(Customer, Contact.Name);
    end;

    local procedure FindCustomerByCompanyName(var Customer: Record Customer; CompanyName: Text[50]);
    begin
        Customer.SetRange(Name, CompanyName);
        Customer.FindFirst();
    end;

    local procedure CreateCustomerTemplateWithLookupValue(LookupValueCode: Code[10]): Code[20]
    var
        CustomerTemplate: Record "Customer Templ.";
        LibraryTemplates: Codeunit "Library - Templates";
    begin
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);

        CustomerTemplate."Lookup Value Code" := LookupValueCode;
        CustomerTemplate.Modify();

        exit(CustomerTemplate.Code);
    end;

    local procedure CreateCustomerCard() CustomerNo: Code[20]
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenNew();
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.Close();
    end;

    local procedure VerifyLookupValueOnSalesHeader(var SalesHeader: Record "Sales Header"; LookupValueCode: Code[10])
    var
        FieldOnTableTxt: Label '%1 on %2';
    // this smells like duplication ;-) - see test example 1
    begin
        Assert.AreEqual(
            LookupValueCode,
            SalesHeader."Lookup Value Code",
            StrSubstNo(
                FieldOnTableTxt,
                SalesHeader.FieldCaption("Lookup Value Code"),
                SalesHeader.TableCaption())
            );
    end;

    local procedure VerifyLookupValueOnCustomer(CustomerNo: Code[20]; LookupValueCode: Code[10])
    var
        Customer: Record Customer;
        FieldOnTableTxt: Label '%1 on %2';
    // this smells like duplication ;-) - see test example 1
    begin
        Customer.Get(CustomerNo);
        Assert.AreEqual(
            LookupValueCode,
            Customer."Lookup Value Code",
            StrSubstNo(
                FieldOnTableTxt,
                Customer.FieldCaption("Lookup Value Code"),
                Customer.TableCaption())
            );
    end;

    [ModalPageHandler]
    procedure HandleConfigTemplates(var CustomerTemplates: TestPage "Select Customer Templ. List")
    begin
        CustomerTemplates.GoToKey(LibraryVariableStorage.DequeueText());
        CustomerTemplates.OK().Invoke();
    end;
}