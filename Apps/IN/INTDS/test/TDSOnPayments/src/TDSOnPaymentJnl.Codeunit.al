codeunit 18803 "TDS On Payment Jnl"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostTDSProvisionalEntryGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        GenJournalSubscribers: codeunit "Gen. Journal Subscribers";
        DocumentNo: Code[20];

    begin
        // [SCENARIO] TDS on provisional entry while creating a invoice using General Journal with party type vendor.
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Post GenJournalLine with party type & party code.
        CreateGenJournalInvoiceProvisionalEntryPartyType(GenJournalLine, Vendor, WorkDate(), true, 0, '');
        DocumentNo := GenJournalLine."Document No.";
        BindSubscription(GenJournalSubscribers);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UnBindSubscription(GenJournalSubscribers);

        // [THEN] G/L & Provisional Entries Verified.
        VerifyGLEntryCount(DocumentNo, 4);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyProvisionalEntryCount(DocumentNo, 1);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,JournalTemplateHandler,ApplyProvisionalEntriesPageHandler,ConfirmHandler,MessageHandler')]
    procedure CheckTDSEntryApplyProvisionalEntryGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        GetGenJournalLine: Record "Gen. Journal Line";
        GenJournalSubscribers: codeunit "Gen. Journal Subscribers";
        CallTaxEngine: Codeunit "Calculate Tax";
        GeneralJournal: TestPage "General Journal";
        DocumentNo: Code[20];
        BalAccountNo: Code[20];
        Amount: Decimal;

    begin
        // [SCENARIO] Check TDS entry, while applying with TDS provisional entry, applied to provision entry must have a value.
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode,Provisional entry.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Post GenJournalLine with party type & party code, apply that entry with new Gen journal line.
        CreateGenJournalInvoiceProvisionalEntryPartyType(GenJournalLine, Vendor, WorkDate(), true, 0, '');
        Amount := GenJournalLine.Amount;
        BalAccountNo := GenJournalLine."Bal. Account No.";
        BindSubscription(GenJournalSubscribers);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UnBindSubscription(GenJournalSubscribers);

        CreateGenJournalInvoiceProvisionalEntryPartyType(GenJournalLine, Vendor, WorkDate(), false, Amount, BalAccountNo);
        DocumentNo := GenJournalLine."Document No.";

        GeneralJournal.OpenEdit();
        GeneralJournal.Filter.SetFilter("Document No.", DocumentNo);
        GeneralJournal."Apply Provisional Entry".Invoke();

        // [THEN] Check the applied provisional entry no.
        GetGenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        CallTaxEngine.CallTaxEngineOnGenJnlLine(GetGenJournalLine, GetGenJournalLine);
        GetGenJournalLine.TestField("Applied Provisional Entry");
        GeneralJournal.Post.Invoke();
    end;

    [Test]
    // [SCENARIO] [14] TDS to be calculated on Vendor Advance Payment through Payment Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinJournals()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    // [SCENARIO] [59] Check if the program is calculating TDS in case Payment is raised to the Vendor using Payment Journal and Threshold Overlook is selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinJournalsWithPANWithoutConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    // [SCENARIO] [64] Check if the program is calculating TDS on Lower rate/zero rate in case Payment is raised to the Vendor is having a certificate using Payment Journal..
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinJournalsWithPANWithConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    // [SCENARIO] [63] Check if the program is calculating TDS on higher rate in case Payment is raised to the Vendor which is not having PAN No. using Payment Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinJournalsWithoutPANWithoutConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, true);
    end;

    [Test]
    // [SCENARIO] [63] Check if the program is calculating TDS on higher rate in case Payment is raised to the Vendor which is not having PAN No. using Payment Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinJournalsWithoutPANWithConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, true);
    end;

    [Test]
    // [SCENARIO] [353883] Check if the program is calculating TDS while creating Invoice using the General Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinPaymentJournalWithPANWithoutConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    // [SCENARIO] [353883] Check if the program is calculating TDS while creating Invoice using the General Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinPaymentJournalWithPANWithConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    // [SCENARIO] [353883] Check if the program is calculating TDS while creating Invoice using the General Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinPaymentJournalWithoutPANWithoutConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, true);
    end;

    [Test]
    // [SCENARIO] [353883] Check if the program is calculating TDS while creating Invoice using the General Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentinPaymentJournalWithoutPANWithConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, true);
    end;

    [Test]
    // [SCENARIO] [353887] Check if the program is calculating TDS while creating a single invoice with multiple expenses using Payment Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPaymentJournalWithPANWithoutConcessionalWithMultiLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup2: Record "TDS Posting Setup";
        TDSSection2: Record "TDS Section";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.CreateTDSPostingSetupForMultipleSection(TDSPostingSetup2, TDSSection2);
        LibraryTDS.AttachSectionWithVendor(TDSPostingSetup2."TDS Section", Vendor."No.", false, true, true);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup2."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GL Entry, TCS Entry created and posted
        VerifyGLEntryCount(DocumentNo, 3);
    end;

    [Test]
    // [SCENARIO] [353893] Check if the program is calculating TDS in case Payment is raised to the Vendor using Payment Journal and Threshold Overlook is selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinJournalWithThresholdOverlookandSurchargeOverlookSelected()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted Payment Journal
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    // [SCENARIO] [353894] Check if the program is calculating TDS in case Payment is raised to the Vendor using Payment Journal and Threshold Overlook is not selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinJournalWithoutThresholdOverlookandSurchargeOverlookSelected()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted GenJournalLine
        CreatePaymentJournalforTDSPayment(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, false, false);
    end;

    [Test]

    // [SCENARIO] [61] Check if the program is calculating TDS in case Payment is raised to the foreign Vendor using Payment Journal and Surcharge Overlook is selected..
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentUsingPaymentJournalOfForeignVendorWithThresholdandSurcharge()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set(NatureOfRemittanceLbl, TDSNatureOfRemittance.Code);
        Storage.Set(ActApplicableLbl, TDSActApplicable.Code);
        Storage.Set(CountryCodeLbl, Vendor."Country/Region Code");
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted Foreign Vendor with General Journal
        CreatePaymentGenJnlLineForTDS(GenJournalLine, Vendor);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        IsForeignVendor := false;
    end;

    [Test]

    // [SCENARIO] [62] Check if the program is calculating TDS in case Payment is raised to the foreign Vendor using Payment Journal and Surcharge Overlook is not selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSPaymentUsingPaymentJournalOfForeignVendorWithoutThresholdandSurcharge()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set(NatureOfRemittanceLbl, TDSNatureOfRemittance.Code);
        Storage.Set(ActApplicableLbl, TDSActApplicable.Code);
        Storage.Set(CountryCodeLbl, Vendor."Country/Region Code");
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Created and Posted Foreign Vendor with General Journal
        CreatePaymentGenJnlLineForTDS(GenJournalLine, Vendor);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries Verified
        VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        IsForeignVendor := false;
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    // [SCENARIO] [55] Check if the program is allowing the posting of the Payment Journal with TDS information where T.A.N No. has not been defined while preparing Payment Journal.
    procedure PostFromPaymentJournalWithoutTANNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        Assert: Codeunit Assert;
        TANNoErr: Label 'T.A.N. No must have a value in TDS Entry', locked = true;
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Create General Journal
        LibraryTDS.RemoveTANOnCompInfo();
        CreatePaymentGenJnlLineForTDS(GenJournalLine, Vendor);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Expected Error Verified
        Assert.ExpectedError(TANNoErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure TDSVendorWithRecurringGeneralMethodBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
    begin
        // [GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        // [WHEN] Create General Journal        
        CreatePaymentGenJnlLineForTDSVendorwithRecurring(GenJournalLine, Vendor."No.");

        // [THEN] Verify allowed section on vendor and recurring method is blank
        VerifyAllowedSectionAndRecurringMethodBlankForTDSVendor(TDSPostingSetup, GenJournalLine, Vendor."No.");
    end;

    local procedure CreatePaymentGenJnlLineForTDSVendorwithRecurring(
        var GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
        GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithDirectPostingNoVAT(), LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::" ");
        GenJournalLine.Validate("TDS Section Code");
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Modify();
    end;

    local procedure VerifyAllowedSectionAndRecurringMethodBlankForTDSVendor(
        TDSPostingSetup: Record "TDS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20])
    var
        AllowedSections: Record "Allowed Sections";
        Assert: Codeunit Assert;
    begin
        AllowedSections.SetRange("Vendor No", VendorNo);
        if AllowedSections.FindFirst() then begin
            Assert.AreEqual(TDSPostingSetup."TDS Section", AllowedSections."TDS Section",
                StrSubstNo(VerifyErr, AllowedSections.FieldCaption("TDS Section"), AllowedSections.TableCaption));
            Assert.AreEqual(GenJournalLine."Recurring Method", GenJournalLine."Recurring Method"::" ",
                StrSubstNo(VerifyErr, GenJournalLine.FieldCaption("Recurring Method"), GenJournalLine.TableCaption));
        end;
    end;

    local procedure CreatePaymentGenJnlLineForTDS(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithDirectPostingNoVAT(), LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("TDS Section Code");
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Modify();
    end;

    local procedure CreatePaymentJournalforTDSPayment(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        TDSSectionCode: Code[10];
        NatureOfRemittance: Code[10];
        ActApplicable: Code[10];
        CountryCode: Code[10];
        Amount: Decimal;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        Amount := LibraryRandom.RandDec(100000, 2);
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            CreateGLAccountWithDirectPostingNoVAT(),
            Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        TDSSectionCode := CopyStr(Storage.Get(SectionCodeLbl), 1, 10);
        GenJournalLine.Validate("TDS Section Code", TDSSectionCode);
        if IsForeignVendor then begin
            NatureOfRemittance := CopyStr(Storage.Get(NatureOfRemittanceLbl), 1, 10);
            ActApplicable := CopyStr(Storage.Get(ActApplicableLbl), 1, 10);
            CountryCode := CopyStr(Storage.Get(CountryCodeLbl), 1, 10);
            GenJournalLine.Validate("Nature of Remittance", NatureOfRemittance);
            GenJournalLine.Validate("Act Applicable", ActApplicable);
            GenJournalLine.Validate("Country/Region Code", CountryCode);
        end;
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    END;

    local procedure CreateGLAccountWithDirectPostingNoVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateTaxRateSetup(TDSSection: Code[10]; AssesseeCode: Code[10]; ConcessionlCode: Code[10]; EffectiveDate: Date)
    var
        Section: Code[10];
        TDSAssesseeCode: Code[10];
        TDSConcessionlCode: Code[10];
    begin
        Section := TDSSection;
        Storage.Set(SectionCodeLbl, Section);
        TDSAssesseeCode := AssesseeCode;
        Storage.Set(TDSAssesseeCodeLbl, TDSAssesseeCode);
        TDSConcessionlCode := ConcessionlCode;
        Storage.Set(TDSConcessionalCodeLbl, TDSConcessionlCode);
        Storage.Set(EffectiveDateLbl, Format(EffectiveDate, 0, 9));
        CreateTaxRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    begin
        Storage.Set(TDSPercentageLbl, Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set(NonPANTDSPercentageLbl, Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set(SurchargePercentageLbl, Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set(ECessPercentageLbl, Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set(SHECessPercentageLbl, Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set(TDSThresholdAmountLbl, Format(LibraryRandom.RandIntInRange(4000, 6000)));
        Storage.Set(SurchargeThresholdAmountLbl, Format(LibraryRandom.RandIntInRange(4000, 6000)));
    end;

    local procedure CreateTaxRate()
    var
        TDSSetup: Record "TDS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TDSSetup.Get() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TDSSetup."Tax Type");
        PageTaxtype.TaxRates.Invoke();
    end;

    local procedure VerifyGLEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyGLEntry: Record "G/L Entry";
        Assert: Codeunit Assert;
    begin
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(DummyGLEntry, ExpectedCount);
    end;

    local procedure VerifyTDSEntry(DocumentNo: Code[20]; TDSBaseAmount: Decimal; CurrencyFactor: Decimal; WithPAN: Boolean; SurchargeOverlook: Boolean; TDSThresholdOverlook: Boolean)
    var
        TDSEntry: Record "TDS Entry";
        Assert: Codeunit Assert;
        ExpectdTDSAmount: Decimal;
        ExpectedSurchargeAmount: Decimal;
        ExpectedEcessAmount: Decimal;
        ExpectedSHEcessAmount: Decimal;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TCS Amount and TCS field Caption';
    begin
        Evaluate(TDSPercentage, Storage.Get(TDSPercentageLbl));
        Evaluate(NonPANTDSPercentage, Storage.Get(NonPANTDSPercentageLbl));
        Evaluate(SurchargePercentage, Storage.Get(SurchargePercentageLbl));
        Evaluate(eCessPercentage, Storage.Get(ECessPercentageLbl));
        Evaluate(SHECessPercentage, Storage.Get(SHECessPercentageLbl));
        Evaluate(TDSThresholdAmount, Storage.Get(TDSThresholdAmountLbl));
        Evaluate(SurchargeThresholdAmount, Storage.Get(SurchargeThresholdAmountLbl));

        if CurrencyFactor = 0 then
            CurrencyFactor := 1;
        if (TDSBaseAmount < TDSThresholdAmount) and (TDSThresholdOverlook = false) then
            ExpectdTDSAmount := 0
        else
            if WithPAN then
                ExpectdTDSAmount := TDSBaseAmount * TDSPercentage / 100 / CurrencyFactor
            else
                ExpectdTDSAmount := TDSBaseAmount * NonPANTDSPercentage / 100 / CurrencyFactor;

        if (TDSBaseAmount < SurchargeThresholdAmount) and (SurchargeOverlook = false) then
            ExpectedSurchargeAmount := 0
        else
            ExpectedSurchargeAmount := ExpectdTDSAmount * SurchargePercentage / 100;
        ExpectedEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * eCessPercentage / 100;
        ExpectedSHEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * SHECessPercentage / 100;
        TDSEntry.SetRange("Document No.", DocumentNo);
        TDSEntry.FindFirst();
        Assert.AreNearlyEqual(
            TDSBaseAmount / CurrencyFactor, TDSEntry."TDS Base Amount", LibraryTDS.GetTDSRoundingPrecision(),
            StrSubstNo(AmountErr, TDSEntry.FieldName("TDS Base Amount"), TDSEntry.TableCaption()));
        if WithPAN then
            Assert.AreEqual(
                TDSPercentage, TDSEntry."TDS %",
                StrSubstNo(AmountErr, TDSEntry.FieldName("TDS %"), TDSEntry.TableCaption()))
        else
            Assert.AreEqual(
                NonPANTDSPercentage, TDSEntry."TDS %",
                StrSubstNo(AmountErr, TDSEntry.FieldName("TDS %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectdTDSAmount, TDSEntry."TDS Amount", LibraryTdS.GetTDSRoundingPrecision(),
            StrSubstNo(AmountErr, TDSEntry.FieldName("TDS Amount"), TDSEntry.TableCaption()));
        Assert.AreEqual(
            SurchargePercentage, TDSEntry."Surcharge %",
            StrSubstNo(AmountErr, TDSEntry.FieldName("Surcharge %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedSurchargeAmount, TDSEntry."Surcharge Amount", LibraryTDS.GetTDSRoundingPrecision(),
            StrSubstNo(AmountErr, TDSEntry.FieldName("Surcharge Amount"), TDSEntry.TableCaption()));
        Assert.AreEqual(
            eCessPercentage, TDSEntry."eCESS %",
            StrSubstNo(AmountErr, TDSEntry.FieldName("eCESS %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedEcessAmount, TDSEntry."eCESS Amount", LibraryTDS.GetTDSRoundingPrecision(),
            StrSubstNo(AmountErr, TDSEntry.FieldName("eCESS Amount"), TDSEntry.TableCaption()));
        Assert.AreEqual(
            SHECessPercentage, TDSEntry."SHE Cess %",
            StrSubstNo(AmountErr, TDSEntry.FieldName("SHE Cess %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedSHEcessAmount, TDSEntry."SHE Cess Amount", LibraryTDS.GetTDSRoundingPrecision(),
            StrSubstNo(AmountErr, TDSEntry.FieldName("SHE Cess Amount"), TDSEntry.TableCaption()));
    end;

    local procedure CreateGenJournalInvoiceProvisionalEntryPartyType(
        var GenJournalLine: Record "Gen. Journal Line";
        var Vendor: Record Vendor;
        PostingDate: Date;
        PatryEntry: Boolean;
        PassedAmount: Decimal;
        PassedBalAccNo: code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        TDSSectionCode: Code[10];
        NatureOfRemittance: Code[10];
        ActApplicable: Code[10];
        CountryCode: Code[10];
        Amount: Decimal;
        AccountNo: Code[20];
        BalAccountNo: Code[20];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        Storage.Set(TemplateNameLbl, GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        AccountNo := CreateGLAccountWithDirectPostingNoVAT();
        if PassedBalAccNo = '' then
            BalAccountNo := CreateGLAccountWithDirectPostingNoVAT()
        else
            BalAccountNo := PassedBalAccNo;

        if PassedAmount = 0 then
            Amount := LibraryRandom.RandDec(100000, 2)
        else
            Amount := Abs(PassedAmount);

        ModifyGenPostingType(AccountNo);
        ModifyGenPostingType(BalAccountNo);
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account",
            AccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account",
            BalAccountNo,
            -Amount);
        GenJournalLine.Validate("Party Type", GenJournalLine."Party Type"::Vendor);
        GenJournalLine.Validate("Party Code", Vendor."No.");
        if PatryEntry then begin
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.Validate("Account No.", AccountNo);
        end;

        GenJournalLine.Validate("Posting Date", PostingDate);
        TDSSectionCode := CopyStr(Storage.Get(SectionCodeLbl), 1, 10);
        GenJournalLine.Validate("TDS Section Code", TDSSectionCode);
        if IsForeignVendor then begin
            NatureOfRemittance := CopyStr(Storage.Get(NatureOfRemittanceLbl), 1, 10);
            ActApplicable := CopyStr(Storage.Get(ActApplicableLbl), 1, 10);
            CountryCode := CopyStr(Storage.Get(CountryCodeLbl), 1, 10);
            GenJournalLine.Validate("Nature of Remittance", NatureOfRemittance);
            GenJournalLine.Validate("Act Applicable", ActApplicable);
            GenJournalLine.Validate("Country/Region Code", CountryCode);
        end;
        if PatryEntry then begin
            GenJournalLine.Validate("Provisional Entry", true);
            GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        end else begin
            GenJournalLine.Validate("TDS Section Code", '');
            GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        end;

        GenJournalLine.Modify(true);
    end;

    local procedure VerifyProvisionalEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        ProvisionalEntry: Record "Provisional Entry";
        Assert: Codeunit Assert;
    begin
        ProvisionalEntry.SetRange("Posted Document No.", DocumentNo);
        Assert.RecordCount(ProvisionalEntry, ExpectedCount);
    end;

    local procedure ModifyGenPostingType(AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        GLAccount."Gen. Posting Type" := GLAccount."Gen. Posting Type"::" ";
        GLAccount.Modify();
    end;

    [ModalPageHandler]
    procedure ApplyProvisionalEntriesPageHandler(var ApplyProvisionalEntries: TestPage "Apply Provisional Entries");
    begin
        ApplyProvisionalEntries.Apply.Invoke();
        ApplyProvisionalEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure JournalTemplateHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.Filter.SetFilter(Name, Storage.Get(TemplateNameLbl));
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; VAR Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        if Message <> SuccessMsg then
            Error(NotPostedErr);
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRates: TestPage "Tax Rates");
    var
        EffectiveDate: Date;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        GenerateTaxComponentsPercentage();
        Evaluate(EffectiveDate, Storage.Get(EffectiveDateLbl), 9);
        Evaluate(TDSPercentage, Storage.Get(TDSPercentageLbl));
        Evaluate(NonPANTDSPercentage, Storage.Get(NonPANTDSPercentageLbl));
        Evaluate(SurchargePercentage, Storage.Get(SurchargePercentageLbl));
        Evaluate(eCessPercentage, Storage.Get(ECessPercentageLbl));
        Evaluate(SHECessPercentage, Storage.Get(SHECessPercentageLbl));
        Evaluate(TDSThresholdAmount, Storage.Get(TDSThresholdAmountLbl));
        Evaluate(SurchargeThresholdAmount, Storage.Get(SurchargeThresholdAmountLbl));

        TaxRates.New();
        TaxRates.AttributeValue1.SetValue(Storage.Get(SectionCodeLbl));
        TaxRates.AttributeValue2.SetValue(Storage.Get(TDSAssesseeCodeLbl));
        TaxRates.AttributeValue3.SetValue(EffectiveDate);
        TaxRates.AttributeValue4.SetValue(Storage.Get(TDSConcessionalCodeLbl));
        if IsForeignVendor then begin
            TaxRates.AttributeValue5.SetValue(Storage.Get(NatureOfRemittanceLbl));
            TaxRates.AttributeValue6.SetValue(Storage.Get(ActApplicableLbl));
            TaxRates.AttributeValue7.SetValue(Storage.Get(CountryCodeLbl))
        end else begin
            TaxRates.AttributeValue5.SetValue('');
            TaxRates.AttributeValue6.SetValue('');
            TaxRates.AttributeValue7.SetValue('');
        end;

        TaxRates.AttributeValue8.SetValue(TDSPercentage);
        TaxRates.AttributeValue9.SetValue(NonPANTDSPercentage);
        TaxRates.AttributeValue10.SetValue(SurchargePercentage);
        TaxRates.AttributeValue11.SetValue(eCessPercentage);
        TaxRates.AttributeValue12.SetValue(SHECessPercentage);
        TaxRates.AttributeValue13.SetValue(TDSThresholdAmount);
        TaxRates.AttributeValue14.SetValue(SurchargeThresholdAmount);
        TaxRates.AttributeValue15.SetValue(0.00);
        TaxRates.OK().Invoke();
    end;

    var
        Vendor: Record Vendor;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTDS: Codeunit "Library-TDS";
        LibraryRandom: Codeunit "Library - Random";
        Storage: Dictionary of [Text, Text];
        IsForeignVendor: Boolean;
        TemplateNameLbl: Label 'TemplateName', Locked = true;
        EffectiveDateLbl: Label 'EffectiveDate', Locked = true;
        TDSPercentageLbl: Label 'TDSPercentage', Locked = true;
        NonPANTDSPercentageLbl: Label 'NonPANTDSPercentage', Locked = true;
        SurchargePercentageLbl: Label 'SurchargePercentage', Locked = true;
        ECessPercentageLbl: Label 'ECessPercentage', Locked = true;
        SHECessPercentageLbl: Label 'SHECessPercentage', Locked = true;
        TDSThresholdAmountLbl: Label 'TDSThresholdAmount', Locked = true;
        SectionCodeLbl: Label 'SectionCode', Locked = true;
        TDSAssesseeCodeLbl: Label 'TDSAssesseeCode', Locked = true;
        SurchargeThresholdAmountLbl: Label 'SurchargeThresholdAmount', Locked = true;
        TDSConcessionalCodeLbl: Label 'TDSConcessionalCode', Locked = true;
        NatureOfRemittanceLbl: Label 'NatureOfRemittance', Locked = true;
        ActApplicableLbl: Label 'ActApplicable', Locked = true;
        CountryCodeLbl: Label 'CountryCode', Locked = true;
        SuccessMsg: Label 'The journal lines were successfully posted.', Locked = true;
        NotPostedErr: Label 'The journal lines were not posted.', Locked = true;
        VerifyErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = Field Caption and Table Caption';
}