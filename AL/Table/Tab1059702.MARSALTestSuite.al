table 1059702 "MARS AL Test Suite"
{
    DataCaptionFields = Name, Description;
    LookupPageID = "MARS AL Test Suites";
    ReplicateData = false;
    Permissions = TableData "MARS AL Test Suite" = rimd, TableData "MARS Test Method Line" = rimd;

    fields
    {
        field(1; Name; Code[10])
        {
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
        }
        field(3; "Tests to Execute"; Integer)
        {
            CalcFormula = Count("MARS Test Method Line" WHERE("Test Suite" = FIELD(Name),
                                                          "Line Type" = CONST(Function),
                                                          Run = CONST(true)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Tests not Executed"; Integer)
        {
            CalcFormula = Count("MARS Test Method Line" WHERE("Test Suite" = FIELD(Name),
                                                          "Line Type" = CONST(Function),
                                                          Run = CONST(true),
                                                          Result = CONST(" ")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Failures; Integer)
        {
            CalcFormula = Count("MARS Test Method Line" WHERE("Test Suite" = FIELD(Name),
                                                          "Line Type" = CONST(Function),
                                                          Run = CONST(true),
                                                          Result = CONST(Failure)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Last Run"; DateTime)
        {
            Editable = false;
        }
        field(7; "Run Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",All,"Active Codeunit","Active Test";
        }
        field(8; "Test Runner Id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TestMethodLine: Record "MARS Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", Name);
        TestMethodLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        TestRunnerMgt: Codeunit "MARS Test Runner - Mgt";
    begin
        if "Test Runner Id" = 0 then
            "Test Runner Id" := TestRunnerMgt.GetDefaultTestRunner();
    end;
}

