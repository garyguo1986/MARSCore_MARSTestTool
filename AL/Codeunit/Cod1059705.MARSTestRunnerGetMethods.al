codeunit 1059705 "MARS Test Runner Get Methods"
{
    Subtype = TestRunner;
    TableNo = "MARS Test Method Line";
    Permissions = TableData "MARS AL Test Suite" = rimd, TableData "MARS Test Method Line" = rimd;

    trigger OnRun()
    var
        ALTestSuite: Record "MARS AL Test Suite";
        TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
    begin
        CurrentTestMethodLine.Copy(Rec);
        ALTestSuite.Get(Rec."Test Suite");
        MaxLineNo := TestSuiteMgt.GetLastTestLineNo(ALTestSuite);
        CODEUNIT.Run(CurrentTestMethodLine."Test Codeunit");
    end;

    var
        CurrentTestMethodLine: Record "MARS Test Method Line";
        MaxLineNo: Integer;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        if (FunctionName = 'OnRun') or (FunctionName = '') then
            exit(true);

        OnGetTestMethods(CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions);
        AddTestMethod(CodeunitID, COPYSTR(FunctionName, 1, 128));

        // Do not run the tests
        exit(false);
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        // This method is invoked by platform
        // It is not used to discover individual test methods
    end;

    local procedure AddTestMethod(CodeunitID: Integer; FunctionName: Text[128])
    var
        TestMethodLine: Record "MARS Test Method Line";
    begin
        MaxLineNo += 10000;
        TestMethodLine."Line No." := MaxLineNo;
        TestMethodLine.Validate("Test Codeunit", CodeunitID);
        TestMethodLine.Validate("Test Suite", CurrentTestMethodLine."Test Suite");
        TestMethodLine.Validate("Line Type", TestMethodLine."Line Type"::"Function");
        TestMethodLine.Validate("Function", FunctionName);
        TestMethodLine.Validate(Run, CurrentTestMethodLine.Run);
        TestMethodLine.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTestMethods(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    begin
    end;
}

