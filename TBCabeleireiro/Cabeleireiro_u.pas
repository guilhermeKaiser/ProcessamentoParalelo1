unit Cabeleireiro_u;

interface

uses
  System.Classes, Vcl.CheckLst, System.SysUtils, Vcl.StdCtrls, System.SyncObjs, Winapi.Messages,
  Vcl.Forms;
type
  Cabeleireiro = class(TThread)
  private
    { Private declarations }
    FilaClientes: TCheckListBox;
    QuantidadeCadeiras: Integer;
    CadeiraCabeleireiro: TCheckBox;
    SecaoCritica: TCriticalSection;
    FTempoParaCorte: Integer;
    FTempoParaDormir: Integer;
    FProgramaExecutando: Boolean;
    procedure setTempoParaCorte(const Value: Integer);
    procedure setTempoParaDormir(const Value: Integer);
    procedure setProgramaExecutando(const Value: Boolean);

    function ExisteClienteEsperando: Boolean;
    function BuscaProximoCliente: Integer;
    procedure DesocupaCadeiraCliente(Const ANumeroCadeira: Integer);
    procedure AtendeCliente;
    procedure Dormir;
    procedure AtualizaStatusCadeiraCabeleireiro(Const AStatus: String; Const AMarcado: Boolean);
  protected
    procedure Execute; override;
  public
    constructor Create(const ACreateSuspended: Boolean; const AProgramaExecutando: boolean;
                       Var AFilaClientes: TCheckListBox; const AQuantidadeCadeiras: Integer;
                       Var ACadeiraCabeleireiro: TCheckBox; Var ASecaoCritica: TCriticalSection);
    property TempoParaCorte: Integer read FTempoParaCorte write setTempoParaCorte;
    property TempoParaDormir: Integer read FTempoParaDormir write setTempoParaDormir;
    property ProgramaExecutando: Boolean read FProgramaExecutando write setProgramaExecutando;
  end;

implementation

{
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure Cabeleireiro.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end;

    or

    Synchronize(
      procedure
      begin
        Form1.Caption := 'Updated in thread via an anonymous method'
      end
      )
    );

  where an anonymous method is passed.

  Similarly, the developer can call the Queue method with similar parameters as
  above, instead passing another TThread class as the first parameter, putting
  the calling thread in a queue with the other thread.

}

{ Cabeleireiro }

procedure Cabeleireiro.AtendeCliente;
begin
  Sleep(TempoParaCorte * 1000);
end;

procedure Cabeleireiro.AtualizaStatusCadeiraCabeleireiro(const AStatus: String;
  const AMarcado: Boolean);
begin
  CadeiraCabeleireiro.Checked := AMarcado;
  CadeiraCabeleireiro.Caption := AStatus;
//  Application.ProcessMessages;
end;

function Cabeleireiro.BuscaProximoCliente: Integer;
var
  i, vMenor, vCadeira: Integer;
begin
  vMenor := 0;
  vCadeira := -1;
  for i := 0 to QuantidadeCadeiras - 1 do
  begin
    if FilaClientes.Checked[i] then
    begin
      if (vMenor = 0) or (StrToIntDef(FilaClientes.Items[i], 0) < vMenor) then
      begin
        vMenor := StrToIntDef(FilaClientes.Items[i], 0);
        vCadeira := i;
      end;
    end;
  end;
  Result := vCadeira;
end;

constructor Cabeleireiro.Create(const ACreateSuspended,
  AProgramaExecutando: boolean; Var AFilaClientes: TCheckListBox;
  const AQuantidadeCadeiras: Integer; Var ACadeiraCabeleireiro: TCheckBox;
  Var ASecaoCritica: TCriticalSection);
begin
  Self.ProgramaExecutando := AProgramaExecutando;
  Self.FilaClientes := AFilaClientes;
  Self.QuantidadeCadeiras := AQuantidadeCadeiras;
  Self.CadeiraCabeleireiro := ACadeiraCabeleireiro;
  Self.SecaoCritica := ASecaoCritica;
  inherited Create(ACreateSuspended);
end;

procedure Cabeleireiro.Dormir;
begin
  Sleep(TempoParaDormir * 1000);
end;

procedure Cabeleireiro.Execute;
var
  vProximoCliente: Integer;
begin
  while ProgramaExecutando do
  begin
    if ExisteClienteEsperando then
    begin
      SecaoCritica.Acquire;
      try
//        AtualizaStatusCadeiraCabeleireiro('Ocupada por Cliente', True);
        CadeiraCabeleireiro.Checked := True;
        CadeiraCabeleireiro.Caption := 'Ocupada por Cliente';

        vProximoCliente := BuscaProximoCliente;
        DesocupaCadeiraCliente(vProximoCliente);
        AtendeCliente;
      finally
        SecaoCritica.Release;
      end;
    end
    else if CadeiraCabeleireiro.Checked then
    begin
      SecaoCritica.Acquire;
      try
        AtendeCliente;
      finally
        SecaoCritica.Release;
      end;
    end
    else
    begin
      SecaoCritica.Acquire;
      try
//        AtualizaStatusCadeiraCabeleireiro('Ocupada pelo Cabeleireiro', True);
        CadeiraCabeleireiro.Checked := True;
        CadeiraCabeleireiro.Caption := 'Ocupada pelo Cabeleireiro';
//        Application.ProcessMessages;

        Dormir;
      finally
        SecaoCritica.Release;
      end;
    end;
//    AtualizaStatusCadeiraCabeleireiro('Cadeira Livre', False);
    CadeiraCabeleireiro.Checked := False;
    CadeiraCabeleireiro.Caption := 'Cadeira Livre';
  end;
end;


function Cabeleireiro.ExisteClienteEsperando: Boolean;
var
  i: Integer;
  vExisteCliente: Boolean;
begin
  vExisteCliente := False;
  for i := 0 to QuantidadeCadeiras - 1 do
  begin
    if FilaClientes.Checked[i] then
    begin
      vExisteCliente := True;
      break;
    end;
  end;
  Result := vExisteCliente;
end;

procedure Cabeleireiro.setProgramaExecutando(const Value: Boolean);
begin
  FProgramaExecutando := Value;
end;

procedure Cabeleireiro.setTempoParaCorte(const Value: Integer);
begin
  FTempoParaCorte := Value;
end;

procedure Cabeleireiro.setTempoParaDormir(const Value: Integer);
begin
  FTempoParaDormir := Value;
end;

procedure Cabeleireiro.DesocupaCadeiraCliente(const ANumeroCadeira: Integer);
begin
  FilaClientes.Items[ANumeroCadeira] := '0';
  FilaClientes.Checked[ANumeroCadeira] := False;
  Application.ProcessMessages;
end;

end.
