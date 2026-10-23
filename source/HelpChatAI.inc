{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

// Compiler version defines. Supported: VCL from Delphi 10.4, FMX from Delphi 12.

// Delphi 10.4 Sydney
{$IFDEF VER340}
  {$DEFINE D10_4+}
{$ENDIF}

// Delphi 11 Alexandria
{$IFDEF VER350}
  {$DEFINE D10_4+}
  {$DEFINE D11+}
{$ENDIF}

// Delphi 12 Athens
{$IFDEF VER360}
  {$DEFINE D10_4+}
  {$DEFINE D11+}
  {$DEFINE D12+}
{$ENDIF}

// Delphi 13 Florence
{$IFDEF VER370}
  {$DEFINE D10_4+}
  {$DEFINE D11+}
  {$DEFINE D12+}
  {$DEFINE D13+}
{$ENDIF}

// Newer, unknown compiler: assume a superset of the latest supported version.
{$IF CompilerVersion > 37}
  {$DEFINE D10_4+}
  {$DEFINE D11+}
  {$DEFINE D12+}
  {$DEFINE D13+}
{$IFEND}

{$IFNDEF D10_4+}
  {$MESSAGE ERROR 'HelpChat requires Delphi 10.4 Sydney or later'}
{$ENDIF}
