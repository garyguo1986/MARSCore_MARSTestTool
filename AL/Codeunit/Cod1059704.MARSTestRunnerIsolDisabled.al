codeunit 1059704 "MARS Test Runner Isol. Disable"
{
    Subtype = TestRunner;
    TableNo = "MARS Test Method Line";
    TestIsolation = Disabled;
    Permissions = TableData "MARS AL Test Suite" = rimd, TableData "MARS Test Method Line" = rimd;

    trigger OnRun()
    begin
        ALTestSuite.Get(Rec."Test Suite");
        CurrentTestMethodLine.Copy(Rec);
        TestRunnerMgt.RunTests(Rec);
    end;

    var
        ALTestSuite: Record "MARS AL Test Suite";
        CurrentTestMethodLine: Record "MARS Test Method Line";
        TestRunnerMgt: Codeunit "MARS Test Runner - Mgt";

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        exit(
          TestRunnerMgt.PlatformBeforeTestRun(
            CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions, ALTestSuite.Name, CurrentTestMethodLine.GetFilter("Line No.")));
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        TestRunnerMgt.PlatformAfterTestRun(
          CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions, IsSuccess, ALTestSuite.Name,
          CurrentTestMethodLine.GetFilter("Line No."));
    end;
}

