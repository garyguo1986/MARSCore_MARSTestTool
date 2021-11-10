page 1059701 "MARS AL Test Suites"
{
    Caption = 'MARS AL Test Suites';
    PageType = List;
    SaveValues = true;
    SourceTable = "MARS AL Test Suite";
    Permissions = TableData "MARS AL Test Suite" = rimd, TableData "MARS Test Method Line" = rimd;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the test suite.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Tests to Execute"; Rec."Tests to Execute")
                {
                    ApplicationArea = All;
                }
                field(Failures; Rec.Failures)
                {
                    ApplicationArea = All;
                }
                field("Tests not Executed"; Rec."Tests not Executed")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }
}


