page 1059707 "MARS Test Role Center"
{
    Caption = 'MARS Test Role Center';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
        }
    }

    actions
    {
        area(creation)
        {
            action(TestRunner)
            {
                ApplicationArea = All;
                Caption = 'Test Runner';
                RunObject = Page "MARS AL Test Tool";
                ToolTip = 'Specifies the action for invoking Test Runner page';
            }
        }
    }
}

