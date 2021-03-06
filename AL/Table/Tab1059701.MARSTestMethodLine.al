table 1059701 "MARS Test Method Line"
{
    ReplicateData = false;
    Permissions = TableData "MARS AL Test Suite" = rimd, TableData "MARS Test Method Line" = rimd;

    fields
    {
        field(1; "Test Suite"; Code[10])
        {
            TableRelation = "MARS AL Test Suite".Name;
        }
        field(2; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(3; "Line Type"; Option)
        {
            Editable = false;
            InitValue = "Codeunit";
            OptionMembers = "Codeunit","Function";

            trigger OnValidate()
            var
                TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
            begin
                TestSuiteMgt.ValidateTestMethodLineType(Rec);
            end;
        }
        field(4; "Test Codeunit"; Integer)
        {
            Editable = false;
            TableRelation = IF ("Line Type" = CONST(Codeunit)) AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit),
                                                                                                  "Object Subtype" = CONST('Test'));

            trigger OnValidate()
            var
                TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
            begin
                TestSuiteMgt.ValidateTestMethodTestCodeunit(Rec);
            end;
        }
        field(5; Name; Text[128])
        {
            Editable = false;

            trigger OnValidate()
            var
                TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
            begin
                TestSuiteMgt.ValidateTestMethodName(Rec);
            end;
        }
        field(6; "Function"; Text[128])
        {
            Editable = false;

            trigger OnValidate()
            var
                TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
            begin
                TestSuiteMgt.ValidateTestMethodFunction(Rec);
            end;
        }
        field(7; Run; Boolean)
        {
            InitValue = true;

            trigger OnValidate()
            var
                TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
            begin
                TestSuiteMgt.ValidateTestMethodRun(Rec);
            end;
        }
        field(8; Result; Option)
        {
            Editable = false;
            OptionMembers = " ",Failure,Success,Skipped;

            trigger OnValidate()
            var
                TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
            begin
                TestSuiteMgt.ClearErrorOnLine(Rec);
            end;
        }
        field(10; "Start Time"; DateTime)
        {
            Editable = false;
        }
        field(11; "Finish Time"; DateTime)
        {
            Editable = false;
        }
        field(12; Level; Integer)
        {
            Editable = false;
        }
        field(50; "Error Message Preview"; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(51; "Error Code"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(52; "Error Message"; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(53; "Error Call Stack"; BLOB)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Suite", Result, "Line Type", Run)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TestSuiteMgt: Codeunit "MARS Test Suite Mgt.";
    begin
        TestSuiteMgt.DeleteChildren(Rec);
    end;
}

