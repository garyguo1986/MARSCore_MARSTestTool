codeunit 1059708 "MARS Test Suite Mgt."
{
    Permissions = TableData "MARS AL Test Suite" = rimd, TableData "MARS Test Method Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        NoTestRunnerSelectedTxt: Label 'No test runner is selected.';
        CannotChangeValueErr: Label 'You cannot change the value of the OnRun.', Locked = true;
        SelectTestsToRunQst: Label '&All,Active &Codeunit,Active &Line', Locked = true;
        SelectCodeunitsToRunQst: Label '&All,Active &Codeunit', Locked = true;
        DefaultTestSuiteNameTxt: Label 'DEFAULT', Locked = true;

    procedure RunTestSuiteSelection(var TestMethodLine: Record "MARS Test Method Line")
    var
        ALTestSuite: Record "MARS AL Test Suite";
        CurrentTestMethodLine: Record "MARS Test Method Line";
        Selection: Integer;
        LineNoFilter: Text;
    begin
        CurrentTestMethodLine.Copy(TestMethodLine);
        ALTestSuite.Get(TestMethodLine."Test Suite");

        if GuiAllowed() then
            Selection := PromptUserToSelectTestsToRun(CurrentTestMethodLine)
        else
            Selection := ALTestSuite."Run Type"::All;

        if Selection <= 0 then
            exit;

        LineNoFilter := GetLineNoFilter(CurrentTestMethodLine, Selection);

        if LineNoFilter <> '' then
            CurrentTestMethodLine.SetFilter("Line No.", LineNoFilter);

        RunTests(CurrentTestMethodLine, ALTestSuite);
    end;

    procedure RunAllTests(var TestMethodLine: Record "MARS Test Method Line")
    var
        ALTestSuite: Record "MARS AL Test Suite";
    begin
        ALTestSuite.Get(TestMethodLine."Test Suite");

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);

        RunTests(TestMethodLine, ALTestSuite);
    end;

    procedure RunNextTest(var TestMethodLine: Record "MARS Test Method Line"): Boolean
    var
        ALTestSuite: Record "MARS AL Test Suite";
    begin
        ALTestSuite.Get(TestMethodLine."Test Suite");
        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetRange(Result, TestMethodLine.Result::" ");
        TestMethodLine.SetRange(Run, true);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);

        if not TestMethodLine.FindFirst() then
            exit(false);

        TestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");

        RunSelectedTests(TestMethodLine);
        exit(true);
    end;

    procedure TestResultsToJSON(var TestMethodLine: Record "MARS Test Method Line"): Text
    var
        CodeunitTestMethodLine: Record "MARS Test Method Line";
        FunctionTestMethodLine: Record "MARS Test Method Line";
        TestResultArray: JsonArray;
        TestResultJson: JsonObject;
        CodeunitResultJson: JsonObject;
        ResultsJsonText: Text;
        ConvertedText: Text;
        ResultInteger: Integer;
    begin
        CodeunitTestMethodLine.Copy(TestMethodLine);
        CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        CodeunitTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        CodeunitTestMethodLine.SetRange(Run, true);
        CodeunitTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
        if not CodeunitTestMethodLine.FindFirst() then
            exit;

        CodeunitResultJson.Add('name', CodeunitTestMethodLine.Name);
        CodeunitResultJson.Add('codeUnit', CodeunitTestMethodLine."Test Codeunit");
        CodeunitResultJson.Add('startTime', CodeunitTestMethodLine."Start Time");
        CodeunitResultJson.Add('finishTime', CodeunitTestMethodLine."Finish Time");

        // Console test runner depends on an integer, not to be affected by translation
        ResultInteger := CodeunitTestMethodLine.Result;
        CodeunitResultJson.Add('result', ResultInteger);

        FunctionTestMethodLine.Copy(CodeunitTestMethodLine);
        FunctionTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Function);

        if FunctionTestMethodLine.FindFirst() then begin
            repeat
                Clear(TestResultJson);
                TestResultJson.Add('method', FunctionTestMethodLine.Name);
                TestResultJson.Add('startTime', FunctionTestMethodLine."Start Time");
                TestResultJson.Add('finishTime', FunctionTestMethodLine."Finish Time");
                ResultInteger := FunctionTestMethodLine.Result;
                TestResultJson.Add('result', ResultInteger);
                if (FunctionTestMethodLine.Result = FunctionTestMethodLine.Result::Failure) then begin
                    TestResultJson.Add('message', GetFullErrorMessage(FunctionTestMethodLine));
                    ConvertedText := GetErrorCallStack(FunctionTestMethodLine);
                    ConvertedText := ConvertedText.Replace('\', ';');
                    ConvertedText := ConvertedText.Replace('"', '');
                    TestResultJson.Add('stackTrace', ConvertedText);
                end;

                TestResultArray.Add(TestResultJson);
            until FunctionTestMethodLine.Next() = 0;

            CodeunitResultJson.Add('testResults', TestResultArray);
        end;

        CodeunitResultJson.WriteTo(ResultsJsonText);

        exit(ResultsJsonText);
    end;

    procedure RunSelectedTests(var TestMethodLine: Record "MARS Test Method Line")
    var
        ALTestSuite: Record "MARS AL Test Suite";
        CurrentCodeunitNumber: Integer;
        LineNoFilter: Text;
    begin
        TestMethodLine.SetCurrentKey("Line No.");
        TestMethodLine.Ascending(true);
        if not TestMethodLine.FindFirst() then
            exit;

        ALTestSuite.Get(TestMethodLine."Test Suite");
        LineNoFilter := '';

        repeat
            if TestMethodLine."Test Codeunit" <> CurrentCodeunitNumber then begin
                CurrentCodeunitNumber := TestMethodLine."Test Codeunit";
                if LineNoFilter <> '' then
                    LineNoFilter += '|';

                if TestMethodLine."Line Type" = TestMethodLine."Line Type"::Codeunit then
                    LineNoFilter += GetLineNoFilter(TestMethodLine, ALTestSuite."Run Type"::"Active Codeunit");

                if TestMethodLine."Line Type" = TestMethodLine."Line Type"::"Function" then
                    LineNoFilter += GetLineNoFilter(TestMethodLine, ALTestSuite."Run Type"::"Active Test");
            end else
                if TestMethodLine."Line Type" = TestMethodLine."Line Type"::"Function" then
                    LineNoFilter += '|' + Format(TestMethodLine."Line No.");
        until TestMethodLine.Next() = 0;

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetFilter("Line No.", LineNoFilter);
        TestMethodLine.FindFirst();
        RunTests(TestMethodLine, ALTestSuite);
    end;

    procedure SelectTestMethods(var ALTestSuite: Record "MARS AL Test Suite")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTests: Page "MARS Select Tests";
    begin
        SelectTests.LookupMode := true;
        if SelectTests.RunModal() = ACTION::LookupOK then begin
            SelectTests.SetSelectionFilter(AllObjWithCaption);
            GetTestMethods(ALTestSuite, AllObjWithCaption);
        end;
    end;

    procedure LookupTestMethodsByRange(var ALTestSuite: Record "MARS AL Test Suite")
    var
        SelectTestsByRange: Page "MARS Select Tests By Range";
    begin
        ALTestSuite.Find();
        SelectTestsByRange.LookupMode := true;
        if SelectTestsByRange.RunModal() = ACTION::LookupOK then
            SelectTestMethodsByRange(ALTestSuite, SelectTestsByRange.GetRange());
    end;

    procedure SelectTestMethodsByRange(var ALTestSuite: Record "MARS AL Test Suite"; TestCodeunitFilter: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetFilter("Object ID", TestCodeunitFilter);
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object Subtype", GetTestObjectSubtype());
        GetTestMethods(ALTestSuite, AllObjWithCaption);
    end;

    procedure SelectTestMethodsByExtension(var ALTestSuite: Record "MARS AL Test Suite"; ExtensionID: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        NAVAppInstalledApp: Record "NAV App Installed App";
        AppExtensionId: Guid;
    begin
        Evaluate(AppExtensionId, ExtensionID);
        NAVAppInstalledApp.SetRange("App ID", AppExtensionId);
        NAVAppInstalledApp.FindFirst();
        AllObjWithCaption.SetRange("App Package ID", NAVAppInstalledApp."Package ID");
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object Subtype", GetTestObjectSubtype());
        GetTestMethods(ALTestSuite, AllObjWithCaption);
    end;

    procedure LookupTestRunner(var ALTestSuite: Record "MARS AL Test Suite")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTestRunner: Page "MARS Select TestRunner";
    begin
        SelectTestRunner.LookupMode := true;
        if SelectTestRunner.RunModal() = ACTION::LookupOK then begin
            SelectTestRunner.GetRecord(AllObjWithCaption);
            ChangeTestRunner(ALTestSuite, AllObjWithCaption."Object ID");
        end;
    end;

    procedure ChangeTestRunner(var ALTestSuite: Record "MARS AL Test Suite"; NewTestRunnerId: Integer)
    begin
        ALTestSuite.Validate("Test Runner Id", NewTestRunnerId);
        ALTestSuite.Modify(true);
    end;

    procedure CreateTestSuite(var TestSuiteName: Code[10])
    var
        ALTestSuite: Record "MARS AL Test Suite";
    begin
        if TestSuiteName = '' then
            TestSuiteName := DefaultTestSuiteNameTxt;

        ALTestSuite.Name := CopyStr(TestSuiteName, 1, MaxStrLen(ALTestSuite.Name));
        ALTestSuite.Insert(true);
    end;

    procedure GetTestMethods(var ALTestSuite: Record "MARS AL Test Suite"; var AllObjWithCaption: Record AllObjWithCaption)
    var
        TestLineNo: Integer;
    begin
        if not AllObjWithCaption.FindSet() then
            exit;

        repeat
            // Must be inside of loop. Test Runner used for discovering tests is adding methods
            TestLineNo := GetLastTestLineNo(ALTestSuite) + 10000;
            AddTestMethod(AllObjWithCaption, ALTestSuite, TestLineNo);
        until AllObjWithCaption.Next() = 0;
    end;

    local procedure PromptUserToSelectTestsToRun(TestMethodLine: Record "MARS Test Method Line"): Integer
    var
        Selection: Integer;
    begin
        if TestMethodLine."Line Type" = TestMethodLine."Line Type"::Codeunit then
            Selection := StrMenu(SelectCodeunitsToRunQst, 1)
        else
            Selection := StrMenu(SelectTestsToRunQst, 3);

        exit(Selection);
    end;

    local procedure GetLineNoFilter(TestMethodLine: Record "MARS Test Method Line"; Selection: Option) LineNoFilter: Text
    var
        DummyALTestSuite: Record "MARS AL Test Suite";
        CodeunitTestMethodLine: Record "MARS Test Method Line";
        MinNumber: Integer;
    begin
        LineNoFilter := '';
        case Selection of
            DummyALTestSuite."Run Type"::"Active Test":
                begin
                    TestMethodLine.TestField("Line Type", TestMethodLine."Line Type"::"Function");
                    LineNoFilter := Format(TestMethodLine."Line No.");
                    CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
                    CodeunitTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
                    CodeunitTestMethodLine.FindFirst();
                    LineNoFilter := StrSubstNo('%1|%2', CodeunitTestMethodLine."Line No.", TestMethodLine."Line No.");
                end;
            DummyALTestSuite."Run Type"::"Active Codeunit":
                begin
                    CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
                    CodeunitTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
                    CodeunitTestMethodLine.SetAscending("Line No.", true);
                    CodeunitTestMethodLine.FindFirst();
                    MinNumber := CodeunitTestMethodLine."Line No.";
                    CodeunitTestMethodLine.FindLast();
                    LineNoFilter :=
                      StrSubstNo('%1..%2', MinNumber, CodeunitTestMethodLine."Line No.");
                end;
        end;
    end;

    procedure GetLastTestLineNo(ALTestSuite: Record "MARS AL Test Suite"): Integer
    var
        TestMethodLine: Record "MARS Test Method Line";
        LineNo: Integer;
    begin
        LineNo := 0;

        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        if TestMethodLine.FindLast() then
            LineNo := TestMethodLine."Line No.";

        exit(LineNo);
    end;

    local procedure AddTestMethod(AllObjWithCaption: Record AllObjWithCaption; ALTestSuite: Record "MARS AL Test Suite"; NextLineNo: Integer)
    var
        TestMethodLine: Record "MARS Test Method Line";
    begin
        TestMethodLine."Test Suite" := ALTestSuite.Name;
        TestMethodLine."Line No." := NextLineNo;
        TestMethodLine."Test Codeunit" := AllObjWithCaption."Object ID";
        TestMethodLine.Validate("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.Name := AllObjWithCaption."Object Name";
        TestMethodLine.Insert(true);

        CODEUNIT.Run(CODEUNIT::"MARS Test Runner Get Methods", TestMethodLine);
    end;

    local procedure GetTestObjectSubtype(): Text
    begin
        exit('Test');
    end;

    procedure DeleteAllMethods(var ALTestSuite: Record "MARS AL Test Suite")
    var
        TestMethodLine: Record "MARS Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.DeleteAll(true);
    end;

    procedure RunTests(var TestMethodLine: Record "MARS Test Method Line"; ALTestSuite: Record "MARS AL Test Suite")
    begin
        CODEUNIT.Run(ALTestSuite."Test Runner Id", TestMethodLine);
    end;

    procedure GetTestRunnerDisplayName(ALTestSuite: Record "MARS AL Test Suite"): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, ALTestSuite."Test Runner Id") then
            exit(NoTestRunnerSelectedTxt);

        exit(StrSubstNo('%1 - %2', ALTestSuite."Test Runner Id", AllObjWithCaption."Object Name"));
    end;

    procedure UpdateRunValueOnChildren(var TestMethodLine: Record "MARS Test Method Line")
    var
        BackupTestMethodLine: Record "MARS Test Method Line";
    begin
        if TestMethodLine."Line Type" = TestMethodLine."Line Type"::"Function" then
            exit;

        BackupTestMethodLine.Copy(TestMethodLine);

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", BackupTestMethodLine."Test Suite");

        TestMethodLine.SETRANGE("Line Type", TestMethodLine."Line Type"::"Function");
        TestMethodLine.SETRANGE("Test Codeunit", BackupTestMethodLine."Test Codeunit");
        TestMethodLine.MODIFYALL(Run, BackupTestMethodLine.Run, TRUE);

        TestMethodLine.Copy(BackupTestMethodLine);
    end;

    procedure DeleteChildren(var TestMethodLine: Record "MARS Test Method Line")
    var
        BackupTestMethodLine: Record "MARS Test Method Line";
    begin
        BackupTestMethodLine.Copy(TestMethodLine);

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        TestMethodLine.SetRange("Test Codeunit", BackupTestMethodLine."Test Codeunit");
        TestMethodLine.SetFilter(Level, '>%1', BackupTestMethodLine.Level);

        if TestMethodLine.IsEmpty() then begin
            TestMethodLine.Copy(BackupTestMethodLine);
            exit;
        end;

        TestMethodLine.DeleteAll();

        TestMethodLine.Copy(BackupTestMethodLine);
    end;

    procedure CalcTestResults(CurrentTestMethodLine: Record "MARS Test Method Line"; var Success: Integer; var Fail: Integer; var Skipped: Integer; var NotExecuted: Integer)
    var
        TestMethodLine: Record "MARS Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", CurrentTestMethodLine."Test Suite");
        TestMethodLine.SetFilter("Function", '<>%1', 'OnRun');
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::"Function");

        TestMethodLine.SetRange(Result, TestMethodLine.Result::Success);
        Success := TestMethodLine.Count();

        TestMethodLine.SetRange(Result, TestMethodLine.Result::Failure);
        Fail := TestMethodLine.Count();

        TestMethodLine.SetRange(Result, TestMethodLine.Result::Skipped);
        Skipped := TestMethodLine.Count();

        TestMethodLine.SetRange(Result, TestMethodLine.Result::" ");
        NotExecuted := TestMethodLine.Count();
    end;

    local procedure GetLineLevel(var TestMethodLine: Record "MARS Test Method Line"): Integer
    begin
        case TestMethodLine."Line Type" of
            TestMethodLine."Line Type"::Codeunit:
                exit(0);
            else
                exit(1);
        end;
    end;

    procedure SetLastErrorOnLine(var TestMethodLine: Record "MARS Test Method Line")
    begin
        TestMethodLine."Error Code" := CopyStr(GetLastErrorCode(), 1, MaxStrLen(TestMethodLine."Error Code"));
        TestMethodLine."Error Message Preview" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TestMethodLine."Error Message Preview"));
        SetFullErrorMessage(TestMethodLine, GetLastErrorText());
        SetErrorCallStack(TestMethodLine, GetLastErrorCallstack());
    end;

    procedure ClearErrorOnLine(var TestMethodLine: Record "MARS Test Method Line")
    begin
        Clear(TestMethodLine."Error Call Stack");
        Clear(TestMethodLine."Error Code");
        Clear(TestMethodLine."Error Message");
        Clear(TestMethodLine."Error Message Preview");
    end;

    procedure GetFullErrorMessage(var TestMethodLine: Record "MARS Test Method Line"): Text
    var
        ErrorMessageInStream: InStream;
        ErrorMessage: Text;
    begin
        TestMethodLine.CalcFields("Error Message");
        if not TestMethodLine."Error Message".HasValue() then
            exit('');

        TestMethodLine."Error Message".CreateInStream(ErrorMessageInStream, GetDefaultTextEncoding());
        ErrorMessageInStream.ReadText(ErrorMessage);
        exit(ErrorMessage);
    end;

    local procedure SetFullErrorMessage(var TestMethodLine: Record "MARS Test Method Line"; ErrorMessage: Text)
    var
        ErrorMessageOutStream: OutStream;
    begin
        TestMethodLine."Error Message".CreateOutStream(ErrorMessageOutStream, GetDefaultTextEncoding());
        ErrorMessageOutStream.WriteText(ErrorMessage);
        TestMethodLine.Modify(true);
    end;

    procedure GetErrorCallStack(var TestMethodLine: Record "MARS Test Method Line"): Text
    var
        ErrorCallStackInStream: InStream;
        ErrorCallStack: Text;
    begin
        TestMethodLine.CalcFields("Error Call Stack");
        if not TestMethodLine."Error Call Stack".HasValue() then
            exit('');

        TestMethodLine."Error Call Stack".CreateInStream(ErrorCallStackInStream, GetDefaultTextEncoding());
        ErrorCallStackInStream.ReadText(ErrorCallStack);
        exit(ErrorCallStack);
    end;

    local procedure SetErrorCallStack(var TestMethodLine: Record "MARS Test Method Line"; ErrorCallStack: Text)
    var
        ErrorCallStackOutStream: OutStream;
    begin
        TestMethodLine."Error Call Stack".CreateOutStream(ErrorCallStackOutStream, GetDefaultTextEncoding());
        ErrorCallStackOutStream.WriteText(ErrorCallStack);
        TestMethodLine.Modify(true);
    end;

    local procedure GetDefaultTextEncoding(): TextEncoding
    begin
        exit(TEXTENCODING::UTF16);
    end;

    procedure GetErrorMessageWithStackTrace(var TestMethodLine: Record "MARS Test Method Line"): Text
    var
        FullErrorMessage: Text;
        NewLine: Text;
    begin
        FullErrorMessage := GetFullErrorMessage(TestMethodLine);

        if FullErrorMessage = '' then
            exit('');

        NewLine[1] := 10;
        FullErrorMessage := StrSubstNo('Error Message: %1 - Error Call Stack: ', FullErrorMessage);
        FullErrorMessage += NewLine + NewLine + GetErrorCallStack(TestMethodLine);
        exit(FullErrorMessage);
    end;

    procedure ValidateTestMethodLineType(var TestMethodLine: Record "MARS Test Method Line")
    begin
        case TestMethodLine."Line Type" of
            TestMethodLine."Line Type"::Codeunit:
                begin
                    TestMethodLine.TestField("Function", '');
                    TestMethodLine.Name := '';
                end;
        end;

        TestMethodLine.Level := GetLineLevel(TestMethodLine);
    end;

    procedure ValidateTestMethodTestCodeunit(var TestMethodLine: Record "MARS Test Method Line")
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if TestMethodLine."Test Codeunit" = 0 then
            exit;

        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, TestMethodLine."Test Codeunit") then
            TestMethodLine.Name := AllObjWithCaption."Object Name";

        TestMethodLine.Level := GetLineLevel(TestMethodLine);
    end;

    procedure ValidateTestMethodName(var TestMethodLine: Record "MARS Test Method Line")
    var
        TestUnitNo: Integer;
    begin
        case TestMethodLine."Line Type" of
            TestMethodLine."Line Type"::"Function":
                TestMethodLine.TestField(Name, TestMethodLine."Function");
            TestMethodLine."Line Type"::Codeunit:
                begin
                    TestMethodLine.TestField(Name);
                    Evaluate(TestUnitNo, TestMethodLine.Name);
                    TestMethodLine.Validate("Test Codeunit", TestUnitNo);
                end;
        end;
    end;

    procedure ValidateTestMethodFunction(var TestMethodLine: Record "MARS Test Method Line")
    begin
        if TestMethodLine."Line Type" <> TestMethodLine."Line Type"::"Function" then begin
            TestMethodLine.TestField("Function", '');
            exit;
        end;

        TestMethodLine.Level := GetLineLevel(TestMethodLine);
        TestMethodLine.Name := TestMethodLine."Function";
    end;

    procedure ValidateTestMethodRun(var CurrentTestMethodLine: Record "MARS Test Method Line")
    var
        TestMethodLine: Record "MARS Test Method Line";
    begin
        if CurrentTestMethodLine."Function" = 'OnRun' then
            Error(CannotChangeValueErr);

        TestMethodLine.Copy(CurrentTestMethodLine);

        UpdateRunValueOnChildren(TestMethodLine);
    end;
}
