Module: odbc-ffi
Author: yduJ
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// $HopeName: DBdylan-odbc!sql.dylan(trunk.5) $

// This file is automatically generated from "sql.j"; do not edit.  (Hah!)


define c-func-with-err SQLAllocConnect
  parameter EnvironmentHandle :: <SQLHENV>;
  output parameter ConnectionHandle :: <LPSQLHDBC>;
  result value :: <SQLRETURN>;
  c-name: "SQLAllocConnect";
end;

define c-func-with-err SQLAllocEnv
  output parameter EnvironmentHandle :: <LPSQLHENV>;
  result value :: <SQLRETURN>;
  c-name: "SQLAllocEnv";
end;

define c-func-with-err SQLAllocHandle
  parameter HandleType :: <SQLSMALLINT>;
  parameter InputHandle :: <SQLHANDLE>;
  output parameter OutputHandle :: <LPSQLHANDLE>;
  result value :: <SQLRETURN>;
  c-name: "SQLAllocHandle";
end;

define c-func-with-err SQLAllocStmt
  parameter ConnectionHandle :: <SQLHDBC>;
  output parameter StatementHandle :: <LPSQLHSTMT>;
  result value :: <SQLRETURN>;
  c-name: "SQLAllocStmt";
end;

define c-func-with-err SQLBindCol
  parameter StatementHandle :: <SQLHSTMT>;
  parameter ColumnNumber :: <SQLUSMALLINT>;
  parameter TargetType :: <SQLSMALLINT>;
  parameter TargetValue :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  parameter StrLen_or_Ind :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLBindCol";
end;

define c-func-with-err SQLBindParam
  parameter StatementHandle :: <SQLHSTMT>;
  parameter ParameterNumber :: <SQLUSMALLINT>;
  parameter ValueType  :: <SQLSMALLINT>;
  parameter ParameterType :: <SQLSMALLINT>;
  parameter LengthPrecision :: <SQLUINTEGER>;
  parameter ParameterScale :: <SQLSMALLINT>;
  parameter ParameterValue :: <SQLPOINTER>;
  parameter StrLen_or_Ind :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLBindParam";
end;

define c-func-with-err SQLCancel
  parameter StatementHandle :: <SQLHSTMT>;
  result value :: <SQLRETURN>;
  c-name: "SQLCancel";
end;

define c-func-with-err SQLCloseCursor
  parameter StatementHandle :: <SQLHSTMT>;
  result value :: <SQLRETURN>;
  c-name: "SQLCloseCursor";
end;

define c-func-with-err SQLColAttribute
  parameter StatementHandle :: <SQLHSTMT>;
  parameter ColumnNumber :: <SQLUSMALLINT>;
  parameter FieldIdentifier :: <SQLUSMALLINT>;
  parameter CharacterAttribute :: <SQLPOINTER>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter StringLength :: <LPSQLSMALLINT>;
  parameter NumericAttribute :: <SQLPOINTER>;
  result value :: <SQLRETURN>;
  c-name: "SQLColAttribute";
end;

define c-func-with-err SQLColumns
  parameter StatementHandle :: <SQLHSTMT>;
  parameter CatalogName :: <LPSQLCHAR>;
  parameter NameLength1 :: <SQLSMALLINT>;
  parameter SchemaName :: <LPSQLCHAR>;
  parameter NameLength2 :: <SQLSMALLINT>;
  parameter TableName  :: <LPSQLCHAR>;
  parameter NameLength3 :: <SQLSMALLINT>;
  parameter ColumnName :: <LPSQLCHAR>;
  parameter NameLength4 :: <SQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLColumns";
end;

define c-func-with-err SQLConnect
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter ServerName :: <LPSQLCHAR>;
  parameter NameLength1 :: <SQLSMALLINT>;
  parameter UserName   :: <LPSQLCHAR>;
  parameter NameLength2 :: <SQLSMALLINT>;
  parameter Authentication :: <LPSQLCHAR>;
  parameter NameLength3 :: <SQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLConnect";
end;

define c-func-with-err SQLCopyDesc
  parameter SourceDescHandle :: <SQLHDESC>;
  parameter TargetDescHandle :: <SQLHDESC>;
  result value :: <SQLRETURN>;
  c-name: "SQLCopyDesc";
end;

define c-func-with-err SQLDataSources
  parameter EnvironmentHandle :: <SQLHENV>;
  parameter Direction  :: <SQLUSMALLINT>;
  parameter ServerName :: <LPSQLCHAR>;
  parameter BufferLength1 :: <SQLSMALLINT>;
  output parameter NameLength1 :: <LPSQLSMALLINT>;
  parameter Description :: <LPSQLCHAR>;
  parameter BufferLength2 :: <SQLSMALLINT>;
  output parameter NameLength2 :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLDataSources";
end;

define c-func-with-err SQLDescribeCol
  parameter StatementHandle :: <SQLHSTMT>;
  parameter ColumnNumber :: <SQLUSMALLINT>;
  parameter ColumnName :: <LPSQLCHAR>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter NameLength :: <LPSQLSMALLINT>;
  output parameter DataType   :: <LPSQLSMALLINT>;
  output parameter ColumnSize :: <LPSQLUINTEGER>;
  output parameter DecimalDigits :: <LPSQLSMALLINT>;
  output parameter Nullable   :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLDescribeCol";
end;

define c-func-with-err SQLDisconnect
  parameter ConnectionHandle :: <SQLHDBC>;
  result value :: <SQLRETURN>;
  c-name: "SQLDisconnect";
end;

define c-func-with-err SQLEndTran
  parameter HandleType :: <SQLSMALLINT>;
  parameter Handle     :: <SQLHANDLE>;
  parameter CompletionType :: <SQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLEndTran";
end;

define C-function SQLError
  parameter EnvironmentHandle :: <SQLHENV>;
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Sqlstate   :: <LPSQLCHAR>;
  output parameter NativeError :: <LPSQLINTEGER>;
  parameter MessageText :: <LPSQLCHAR>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter TextLength :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLError";
end;

define c-func-with-err SQLExecDirect
  parameter StatementHandle :: <SQLHSTMT>;
  parameter StatementText :: <LPSQLCHAR>;
  parameter TextLength :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLExecDirect";
end;

define c-func-with-err SQLExecute
  parameter StatementHandle :: <SQLHSTMT>;
  result value :: <SQLRETURN>;
  c-name: "SQLExecute";
end;

define c-func-with-err SQLFetch
  parameter StatementHandle :: <SQLHSTMT>;
  result value :: <SQLRETURN>;
  c-name: "SQLFetch";
end;

define c-func-with-err SQLFetchScroll
  parameter StatementHandle :: <SQLHSTMT>;
  parameter FetchOrientation :: <SQLSMALLINT>;
  parameter FetchOffset :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLFetchScroll";
end;

define c-func-with-err SQLFreeConnect
  parameter ConnectionHandle :: <SQLHDBC>;
  result value :: <SQLRETURN>;
  c-name: "SQLFreeConnect";
end;

define c-func-with-err SQLFreeEnv
  parameter EnvironmentHandle :: <SQLHENV>;
  result value :: <SQLRETURN>;
  c-name: "SQLFreeEnv";
end;

define c-func-with-err SQLFreeHandle
  parameter HandleType :: <SQLSMALLINT>;
  parameter Handle     :: <SQLHANDLE>;
  result value :: <SQLRETURN>;
  c-name: "SQLFreeHandle";
end;

define c-func-with-err SQLFreeStmt
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Option     :: <SQLUSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLFreeStmt";
end;

define c-func-with-err SQLGetConnectAttr
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter Attribute  :: <SQLINTEGER>;
  parameter Value      :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  output parameter StringLength :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetConnectAttr";
end;

define c-func-with-err SQLGetConnectOption
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter Option     :: <SQLUSMALLINT>;
  parameter Value      :: <SQLPOINTER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetConnectOption";
end;

define c-func-with-err SQLGetCursorName
  parameter StatementHandle :: <SQLHSTMT>;
  parameter CursorName :: <LPSQLCHAR>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter NameLength :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetCursorName";
end;

define c-func-with-err SQLGetData
  parameter StatementHandle :: <SQLHSTMT>;
  parameter ColumnNumber :: <SQLUSMALLINT>;
  parameter TargetType :: <SQLSMALLINT>;
  parameter TargetValue :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  output parameter StrLen_or_Ind :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetData";
end;

define c-func-with-err SQLGetDescField
  parameter DescriptorHandle :: <SQLHDESC>;
  parameter RecNumber  :: <SQLSMALLINT>;
  parameter FieldIdentifier :: <SQLSMALLINT>;
  parameter Value      :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  output parameter StringLength :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetDescField";
end;

define c-func-with-err SQLGetDescRec
  parameter DescriptorHandle :: <SQLHDESC>;
  parameter RecNumber  :: <SQLSMALLINT>;
  parameter Name       :: <LPSQLCHAR>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter StringLength :: <LPSQLSMALLINT>;
  output parameter Type       :: <LPSQLSMALLINT>;
  output parameter SubType    :: <LPSQLSMALLINT>;
  output parameter Length     :: <LPSQLINTEGER>;
  output parameter Precision  :: <LPSQLSMALLINT>;
  output parameter Scale      :: <LPSQLSMALLINT>;
  output parameter Nullable   :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetDescRec";
end;

define c-func-with-err SQLGetDiagField
  parameter HandleType :: <SQLSMALLINT>;
  parameter Handle     :: <SQLHANDLE>;
  parameter RecNumber  :: <SQLSMALLINT>;
  parameter DiagIdentifier :: <SQLSMALLINT>;
  parameter DiagInfo   :: <SQLPOINTER>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter StringLength :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetDiagField";
end;

define c-func-with-err SQLGetDiagRec
  parameter HandleType :: <SQLSMALLINT>;
  parameter Handle     :: <SQLHANDLE>;
  parameter RecNumber  :: <SQLSMALLINT>;
  parameter Sqlstate   :: <LPSQLCHAR>;
  output parameter NativeError :: <LPSQLINTEGER>;
  parameter MessageText :: <LPSQLCHAR>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter TextLength :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetDiagRec";
end;

define c-func-with-err SQLGetEnvAttr
  parameter EnvironmentHandle :: <SQLHENV>;
  parameter Attribute  :: <SQLINTEGER>;
  parameter Value      :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  output parameter StringLength :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetEnvAttr";
end;

define c-func-with-err SQLGetFunctions
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter FunctionId :: <SQLUSMALLINT>;
  output parameter Supported  :: <LPSQLUSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetFunctions";
end;

define c-func-with-err SQLGetInfo
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter InfoType   :: <SQLUSMALLINT>;
  parameter InfoValue  :: <SQLPOINTER>;
  parameter BufferLength :: <SQLSMALLINT>;
  output parameter StringLength :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetInfo";
end;

define c-func-with-err SQLGetStmtAttr
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Attribute  :: <SQLINTEGER>;
  parameter Value      :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  output parameter StringLength :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetStmtAttr";
end;

define c-func-with-err SQLGetStmtOption
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Option     :: <SQLUSMALLINT>;
  parameter Value      :: <SQLPOINTER>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetStmtOption";
end;

define c-func-with-err SQLGetTypeInfo
  parameter StatementHandle :: <SQLHSTMT>;
  parameter DataType   :: <SQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLGetTypeInfo";
end;

define c-func-with-err SQLNumResultCols
  parameter StatementHandle :: <SQLHSTMT>;
  output parameter ColumnCount :: <LPSQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLNumResultCols";
end;

define c-func-with-err SQLParamData
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Value      :: <LPSQLPOINTER>;
  result value :: <SQLRETURN>;
  c-name: "SQLParamData";
end;

define c-func-with-err SQLPrepare
  parameter StatementHandle :: <SQLHSTMT>;
  parameter StatementText :: <LPSQLCHAR>;
  parameter TextLength :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLPrepare";
end;

define c-func-with-err SQLPutData
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Data       :: <SQLPOINTER>;
  parameter StrLen_or_Ind :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLPutData";
end;

define c-func-with-err SQLRowCount
  parameter StatementHandle :: <SQLHSTMT>;
  output parameter RowCount   :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLRowCount";
end;

define c-func-with-err SQLSetConnectAttr
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter Attribute  :: <SQLINTEGER>;
  parameter Value      :: <SQLUINTEGER>; // is this going to work for strings?
  parameter StringLength :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetConnectAttr";
end;

define c-func-with-err SQLSetConnectOption
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter Option     :: <SQLUSMALLINT>;
  parameter Value      :: <SQLUINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetConnectOption";
end;

define c-func-with-err SQLSetCursorName
  parameter StatementHandle :: <SQLHSTMT>;
  parameter CursorName :: <LPSQLCHAR>;
  parameter NameLength :: <SQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetCursorName";
end;

define c-func-with-err SQLSetDescField
  parameter DescriptorHandle :: <SQLHDESC>;
  parameter RecNumber  :: <SQLSMALLINT>;
  parameter FieldIdentifier :: <SQLSMALLINT>;
  parameter Value      :: <SQLPOINTER>;
  parameter BufferLength :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetDescField";
end;

define c-func-with-err SQLSetDescRec
  parameter DescriptorHandle :: <SQLHDESC>;
  parameter RecNumber  :: <SQLSMALLINT>;
  parameter Type       :: <SQLSMALLINT>;
  parameter SubType    :: <SQLSMALLINT>;
  parameter Length     :: <SQLINTEGER>;
  parameter Precision  :: <SQLSMALLINT>;
  parameter Scale      :: <SQLSMALLINT>;
  parameter Data       :: <SQLPOINTER>;
  parameter StringLength :: <LPSQLINTEGER>;
  parameter Indicator  :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetDescRec";
end;

define c-func-with-err SQLSetEnvAttr
  parameter EnvironmentHandle :: <SQLHENV>;
  parameter Attribute  :: <SQLINTEGER>;
  parameter Value      :: <SQLINTEGER>; //was sqlpointer
  parameter StringLength :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetEnvAttr";
end;

define c-func-with-err SQLSetParam
  parameter StatementHandle :: <SQLHSTMT>;
  parameter ParameterNumber :: <SQLUSMALLINT>;
  parameter ValueType  :: <SQLSMALLINT>;
  parameter ParameterType :: <SQLSMALLINT>;
  parameter LengthPrecision :: <SQLUINTEGER>;
  parameter ParameterScale :: <SQLSMALLINT>;
  parameter ParameterValue :: <SQLPOINTER>;
  parameter StrLen_or_Ind :: <LPSQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetParam";
end;

define c-func-with-err SQLSetStmtAttr
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Attribute  :: <SQLINTEGER>;
  parameter Value      :: <SQLPOINTER>;
  parameter StringLength :: <SQLINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetStmtAttr";
end;

define c-func-with-err SQLSetStmtOption
  parameter StatementHandle :: <SQLHSTMT>;
  parameter Option     :: <SQLUSMALLINT>;
  parameter Value      :: <SQLUINTEGER>;
  result value :: <SQLRETURN>;
  c-name: "SQLSetStmtOption";
end;

define c-func-with-err SQLSpecialColumns
  parameter StatementHandle :: <SQLHSTMT>;
  parameter IdentifierType :: <SQLUSMALLINT>;
  parameter CatalogName :: <LPSQLCHAR>;
  parameter NameLength1 :: <SQLSMALLINT>;
  parameter SchemaName :: <LPSQLCHAR>;
  parameter NameLength2 :: <SQLSMALLINT>;
  parameter TableName  :: <LPSQLCHAR>;
  parameter NameLength3 :: <SQLSMALLINT>;
  parameter Scope      :: <SQLUSMALLINT>;
  parameter Nullable   :: <SQLUSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLSpecialColumns";
end;

define c-func-with-err SQLStatistics
  parameter StatementHandle :: <SQLHSTMT>;
  parameter CatalogName :: <LPSQLCHAR>;
  parameter NameLength1 :: <SQLSMALLINT>;
  parameter SchemaName :: <LPSQLCHAR>;
  parameter NameLength2 :: <SQLSMALLINT>;
  parameter TableName  :: <LPSQLCHAR>;
  parameter NameLength3 :: <SQLSMALLINT>;
  parameter Unique     :: <SQLUSMALLINT>;
  parameter Reserved   :: <SQLUSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLStatistics";
end;

define c-func-with-err SQLTables
  parameter StatementHandle :: <SQLHSTMT>;
  parameter CatalogName :: <LPSQLCHAR>;
  parameter NameLength1 :: <SQLSMALLINT>;
  parameter SchemaName :: <LPSQLCHAR>;
  parameter NameLength2 :: <SQLSMALLINT>;
  parameter TableName  :: <LPSQLCHAR>;
  parameter NameLength3 :: <SQLSMALLINT>;
  parameter TableType  :: <LPSQLCHAR>;
  parameter NameLength4 :: <SQLSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLTables";
end;

define c-func-with-err SQLTransact
  parameter EnvironmentHandle :: <SQLHENV>;
  parameter ConnectionHandle :: <SQLHDBC>;
  parameter CompletionType :: <SQLUSMALLINT>;
  result value :: <SQLRETURN>;
  c-name: "SQLTransact";
end;

