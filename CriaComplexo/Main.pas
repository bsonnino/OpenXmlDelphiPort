unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, xmldom, XMLIntf, msxmldom, XMLDoc, System.Zip;

type
  TMainFrm = class(TForm)
    XMLDocument1: TXMLDocument;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    procedure CriaContentTypes(AStream: TStream);
    procedure CriaDocumento(AStream: TStream);
    procedure CriaRels(AStream: TStream);
    procedure LimpaXML;
    procedure CriaCabecalhoXml;
    procedure AdicionaFonte(Body: IXMLNode; NomeFonte: String);
    procedure CriaDocRels(AStream: TStream);
    procedure CriaHeader(AStream: TStream);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.dfm}

procedure TMainFrm.LimpaXML;
begin
  XMLDocument1.XML.Text := '';
end;

procedure TMainFrm.CriaCabecalhoXml;
begin
  XMLDocument1.Options := [doNodeAutoIndent];
  XMLDocument1.Active := True;
  // Cabeçalho
  XMLDocument1.Encoding := 'UTF-8';
  XMLDocument1.Version := '1.0';
  XMLDocument1.StandAlone := 'yes';
end;

procedure TMainFrm.CriaContentTypes(AStream: TStream);
var
  Root: IXMLNode;
  Tipo: IXMLNode;
begin
  LimpaXML;
  CriaCabecalhoXml;
  // Nó raiz
  Root := XMLDocument1.addChild('Types',
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
  Tipo := Root.addChild('Override');
  Tipo.Attributes['PartName'] := '/word/header1.xml';
  Tipo.Attributes['ContentType'] :=
    'application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml';
  // Grava no stream de saída
  XMLDocument1.SaveToStream(AStream);
  AStream.Position := 0;
end;

procedure TMainFrm.CriaRels(AStream: TStream);
var
  Root: IXMLNode;
  Rel: IXMLNode;
begin
  LimpaXML;
  CriaCabecalhoXml;
  Root := XMLDocument1.addChild('Relationships',
    'http://schemas.openxmlformats.org/package/2006/relationships');
  Rel := Root.addChild('Relationship');
  Rel.Attributes['Id'] := 'rId1';
  Rel.Attributes['Type'] :=
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument';
  Rel.Attributes['Target'] := 'word/document.xml';
  XMLDocument1.SaveToStream(AStream);
  AStream.Position := 0;
end;

procedure TMainFrm.CriaDocRels(AStream: TStream);
var
  Root: IXMLNode;
  Rel: IXMLNode;
begin
  LimpaXML;
  CriaCabecalhoXml;
  Root := XMLDocument1.addChild('Relationships',
    'http://schemas.openxmlformats.org/package/2006/relationships');
  Rel := Root.addChild('Relationship');
  Rel.Attributes['Id'] := 'rId1';
  Rel.Attributes['Type'] :=
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships/header';
  Rel.Attributes['Target'] := 'header1.xml';
  XMLDocument1.SaveToStream(AStream);
  AStream.Position := 0;
end;

procedure TMainFrm.AdicionaFonte(Body: IXMLNode; NomeFonte: String);
var
  Fonte: IXMLNode;
  Run: IXMLNode;
  RunPr: IXMLNode;
begin
  Run := Body.addChild('w:p').addChild('w:r');
  RunPr := Run.addChild('w:rPr');
  Fonte := RunPr.addChild('w:rFonts');
  Fonte.Attributes['w:ascii'] := NomeFonte;
  Fonte.Attributes['w:hAnsi'] := NomeFonte;
  Fonte.Attributes['w:cs'] := NomeFonte;
  RunPr.addChild('w:sz').Attributes['w:val'] := 30;
  Run.addChild('w:t').NodeValue := NomeFonte;
  Run.addChild('w:tab');
  Run.addChild('w:t').NodeValue :=
    'The quick brown fox jumps over the lazy dog';
end;

procedure TMainFrm.CriaDocumento(AStream: TStream);
var
  Root, Body, PgSz: IXMLNode;
  i: Integer;
  SectPr: IXMLNode;
  Header: IXMLNode;
begin
  LimpaXML;
  CriaCabecalhoXml;
  Root := XMLDocument1.addChild('w:wordDocument');
  Root.DeclareNamespace('w',
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
  Root.DeclareNamespace('r',
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships');
  Body := Root.addChild('w:body');
  for i := 0 to Screen.Fonts.Count - 1 do
    AdicionaFonte(Body, Screen.Fonts[i]);
  SectPr := Body.addChild('sectPr');
  Header := SectPr.addChild('w:headerReference');
  Header.Attributes['w:type'] := 'default';
  Header.Attributes['r:id'] := 'rId1';
  PgSz := SectPr.addChild('w:pgSz');
  PgSz.Attributes['w:w'] := Round(297 / 25.4 * 1440);
  PgSz.Attributes['w:h'] := Round(210 / 25.4 * 1440);
  PgSz := SectPr.addChild('w:pgMar');
  PgSz.Attributes['w:top'] := 1440;
  PgSz.Attributes['w:bottom'] := 1440;
  PgSz.Attributes['w:left'] := 720;
  PgSz.Attributes['w:right'] := 720;
  PgSz.Attributes['w:header'] := 720;
  PgSz.Attributes['w:footer'] := 720;
  XMLDocument1.SaveToStream(AStream);
  AStream.Position := 0;
end;

procedure TMainFrm.CriaHeader(AStream: TStream);
var
  Root, Header, PTab: IXMLNode;
begin
  LimpaXML;
  CriaCabecalhoXml;
  Root := XMLDocument1.addChild('w:hdr');
  Root.DeclareNamespace('w',
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
  Header := Root.addChild('w:p');
  Header.addChild('w:r').addChild('w:t').NodeValue := 'Texto 1';
  PTab := Header.addChild('w:r').addChild('w:ptab');
  PTab.Attributes['w:relativeTo'] := 'margin';
  PTab.Attributes['w:alignment'] := 'center';
  PTab.Attributes['w:leader'] := 'none';
  Header.addChild('w:r').addChild('w:t').NodeValue := 'Texto 2';
  PTab := Header.addChild('w:r').addChild('w:ptab');
  PTab.Attributes['w:relativeTo'] := 'margin';
  PTab.Attributes['w:alignment'] := 'right';
  PTab.Attributes['w:leader'] := 'none';
  Header.addChild('w:fldSimple').Attributes['w:instr'] := 'PAGE \* MERGEFORMAT';
  XMLDocument1.SaveToStream(AStream);
  AStream.Position := 0;
end;

procedure TMainFrm.Button1Click(Sender: TObject);
var
  ZipFile: TZipFile;
  MemStream: TMemoryStream;
begin
  ZipFile := TZipFile.Create();
  try
    ZipFile.Open('ArquivoComplexo.docx', TZipMode.zmWrite);
    MemStream := TMemoryStream.Create();
    try
      CriaContentTypes(MemStream);
      ZipFile.Add(MemStream, '[Content_Types].xml');
      MemStream.Clear;
      CriaRels(MemStream);
      ZipFile.Add(MemStream, '_rels\.rels');
      MemStream.Clear;
      CriaDocumento(MemStream);
      ZipFile.Add(MemStream, 'word\document.xml');
      MemStream.Clear;
      CriaDocRels(MemStream);
      ZipFile.Add(MemStream, 'word\_rels\document.xml.rels');
      MemStream.Clear;
      CriaHeader(MemStream);
      ZipFile.Add(MemStream, 'word\header1.xml');
    finally
      MemStream.Free;
    end;
  finally
    ZipFile.Close();
    ZipFile.Free;
  end;
end;

end.
