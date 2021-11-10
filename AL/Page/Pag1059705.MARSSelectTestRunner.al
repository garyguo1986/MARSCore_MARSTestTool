page 1059705 "MARS Select TestRunner"
{
    Caption = 'MARS Select TestRunner';
    Editable = false;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableView = WHERE("Object Type" = CONST(Codeunit),
                            "Object Subtype" = CONST('TestRunner'));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                }
                field("Object Name"; Rec."Object Name")
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


