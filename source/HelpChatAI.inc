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

// Compiler version defines. Supported: the engine and the server from Delphi
// 10.2 Tokyo, the VCL components from 10.4 Sydney, FMX from 12 Athens. The
// components say so themselves (Vcl.HelpChatAI, Vcl.HelpChatAI.Panel,
// FMX.HelpChatAI): the engine units must not, or an application of 10.2 or
// 10.3 that uses only the engine could not build.

{$IF CompilerVersion >= 32}  // Delphi 10.2 Tokyo
  {$DEFINE D10_2+}
{$IFEND}
{$IF CompilerVersion >= 33}  // Delphi 10.3 Rio
  {$DEFINE D10_3+}
{$IFEND}
{$IF CompilerVersion >= 34}  // Delphi 10.4 Sydney
  {$DEFINE D10_4+}
{$IFEND}
{$IF CompilerVersion >= 35}  // Delphi 11 Alexandria
  {$DEFINE D11+}
{$IFEND}
{$IF CompilerVersion >= 36}  // Delphi 12 Athens
  {$DEFINE D12+}
{$IFEND}
{$IF CompilerVersion >= 37}  // Delphi 13 Florence
  {$DEFINE D13+}
{$IFEND}

{$IFNDEF D10_2+}
  {$MESSAGE ERROR 'The HelpChat engine requires Delphi 10.2 Tokyo or later'}
{$ENDIF}
