unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, xmldom, XMLIntf, msxmldom, XMLDoc, System.Zip;

type
  TMainFrm = class(TForm)
    Label1: TLabel;
    Memo1: TMemo;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    function CriaContentTypes(): TStream;
    function CriaDocumento(): TStream;
    function CriaRels(): TStream;
    function CriaXml: IXmlDocument;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.dfm}

function TMainFrm.CriaXml: IXmlDocument;
begin
  Result := TXmlDocument.Create(nil);
  Result.Options := [doNodeAutoIndent];
  Result.Active := True;
  Result.Encoding := 'UTF-8';
  Result.Version := '1.0';
  Result.StandAlone := 'yes';
end;

function TMainFrm.CriaContentTypes(): TStream;
var
  Root: IXmlNode;
  Tipo: IXmlNode;
  XMLDoc: IXmlDocument;
begin
  Result := TMemoryStream.Create();
  XMLDoc := CriaXml;
  // Nó raiz
  Root := XMLDoc.addChild('Types',
    'http://schemas.openxmlformats.org/package/2006/content-types');
  // Definição de tipos
  Tipo := Root.addChild('Default');
  Tipo.Attributes['Extension'] := 'rels';
  Tipo.Attributes['ContentType'] :=
    'application/vnd.openxmlformats-package.relationships+xml';
  Tipo := Root.addChild('Default');
  Tipo.Attributes['Extension'] := 'xml';
  Tipo.Attributes['ContentType'] :=
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml';
  // Grava no stream de saída
  XMLDoc.SaveToStream(Result);
  Result.Position := 0;
end;

function TMainFrm.CriaRels(): TStream;
var
  Root: IXmlNode;
  Rel: IXmlNode;
  XMLDoc: IXmlDocument;
begin
  Result := TMemoryStream.Create();
  XMLDoc := CriaXml;
  // Nó raiz
  Root := XMLDoc.addChild('Relationships',
    'http://schemas.openxmlformats.org/package/2006/relationships');
  // Definição de relações
  Rel := Root.addChild('Relationship');
  Rel.Attributes['Id'] := 'rId1';
  Rel.Attributes['Type'] :=
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument';
  Rel.Attributes['Target'] := 'word/document.xml';
  // Grava no stream de saída
  XMLDoc.SaveToStream(Result);
  Result.Position := 0;
end;

function TMainFrm.CriaDocumento(): TStream;
var
  Root: IXmlNode;
  XMLDoc: IXmlDocument;
begin
  Result := TMemoryStream.Create();
  XMLDoc := CriaXml;
  // Nó raiz
  Root := XMLDoc.addChild('wordDocument',
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
  // Grava texto
  Root.addChild('body').addChild('p').addChild('r').addChild('t').NodeValue :=
    Memo1.Text;
  // Grava no stream de saída
  XMLDoc.SaveToStream(Result);
  Result.Position := 0;
end;

procedure TMainFrm.Button1Click(Sender: TObject);
var
  zipFile: TZipFile;
  contentTypes: TStream;
  rels: TStream;
  doc: TStream;
begin
  zipFile := TZipFile.Create();
  try
    zipFile.Open('ArquivoSimples.docx', TZipMode.zmWrite);
    contentTypes := CriaContentTypes();
    try
      zipFile.Add(contentTypes, '[Content_Types].xml');
    finally
      contentTypes.Free;
    end;
    rels := CriaRels();
    try
      zipFile.Add(rels, '_rels\.rels');
    finally
      rels.Free;
    end;
    doc := CriaDocumento();
    try
      zipFile.Add(doc, 'word\document.xml');
    finally
      doc.Free;
    end;
  finally
    zipFile.Close();
    zipFile.Free;
  end;
end;

end.
