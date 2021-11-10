codeunit 1059710 "MARS Test Demo"
{
    Subtype = Test;
    [Test]
    procedure SuccessFun()
    var
        LibraryAssertL: Codeunit "MARS Library Assert";
        Var1L: Variant;
        Var2L: Variant;
    begin
        Var1L := 1;
        Var2L := 1;
        LibraryAssertL.AreEqual(Var1L, Var2L, '');
    end;

    [Test]
    procedure FailedFun()
    var
        LibraryAssertL: Codeunit "MARS Library Assert";
        Var1L: Variant;
        Var2L: Variant;
    begin
        Var1L := '1';
        Var2L := '2';
        LibraryAssertL.AreEqual(Var1L, Var2L, '');
    end;
}
