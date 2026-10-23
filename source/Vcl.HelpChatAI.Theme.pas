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

/// <summary>
///  Produces a <see cref="THelpChatTheme" /> from the active VCL style, so the
///  panel follows the application look. Two sources, in this order: a curated
///  table of the VCL styles shipped with Delphi (the colours StyledComponents
///  registers for each style: text, panel, hot/accent, borders, light or dark),
///  then, for a style not in the table, the colours the style itself reports
///  through <c>StyleServices</c>. The page background comes from the style's
///  window colour; the accent is the more saturated of the hot and hot-border
///  colours of the table, since some styles use a pale hover and keep the
///  brand colour for the border.
/// </summary>
unit Vcl.HelpChatAI.Theme;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  Vcl.Graphics,
  HelpChatAI.Theme;

type
  /// <summary>One row of the curated table: the colours StyledComponents
  /// registers for a VCL style (RegisterThemeAttributes).</summary>
  THelpChatVclStyleColors = record
    Name: string;
    IsDark: Boolean;
    Text: string;
    TextOnAccent: string;
    Button: string;
    Panel: string;
    Accent: string;
    Border: string;
    BorderHot: string;
  end;

/// <summary>Name of the active VCL style ('Windows' when none); the IDE
/// designer styles are mapped to 'Windows' as StyledComponents does.</summary>
function HelpChatActiveVclStyleName: string;
/// <summary>Looks up a style in the curated table (case-insensitive).</summary>
function HelpChatFindVclStyleColors(const AStyleName: string; out AColors: THelpChatVclStyleColors): Boolean;
/// <summary>The theme of a VCL style: the active one when AStyleName is empty.</summary>
function HelpChatThemeFromVclStyle(const AStyleName: string = ''): THelpChatTheme;
/// <summary>"#rrggbb" of a TColor (system colours resolved).</summary>
function HelpChatColorToHex(const AColor: TColor): string;

const
  HELPCHAT_VCL_STYLE_TABLE: array[0..116] of THelpChatVclStyleColors = (
    (Name: 'Windows'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#e0eef9'; Border: '#d0d0d0'; BorderHot: '#0078d4'),
    (Name: 'Amakrits'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#292929'; Panel: '#292929'; Accent: '#6ee4d3'; Border: '#020202'; BorderHot: '#020202'),
    (Name: 'Amethyst Kamri'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#cdd1e2'; Panel: '#cdd1e2'; Accent: '#f99369'; Border: '#868db0'; BorderHot: '#868db0'),
    (Name: 'Aqua Graphite'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#0070bb'; Panel: '#0070bb'; Accent: '#1585cc'; Border: '#043f5c'; BorderHot: '#043f5c'),
    (Name: 'Aqua Light Slate'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#f1f1f1'; Panel: '#f1f1f1'; Accent: '#a9d8f2'; Border: '#9c9c9c'; BorderHot: '#9c9c9c'),
    (Name: 'Calypso'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#44617c'; Panel: '#44617c'; Accent: '#80ceb5'; Border: '#44617c'; BorderHot: '#80ceb5'),
    (Name: 'Calypso LE'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#44617c'; Panel: '#44617c'; Accent: '#80ceb5'; Border: '#44617c'; BorderHot: '#80ceb5'),
    (Name: 'Calypso SE'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#44617c'; Panel: '#44617c'; Accent: '#6bafe2'; Border: '#44617c'; BorderHot: '#6bafe2'),
    (Name: 'Calypso SLE'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#44617c'; Panel: '#44617c'; Accent: '#6bafe2'; Border: '#44617c'; BorderHot: '#6bafe2'),
    (Name: 'Carbon'; IsDark: True; Text: '#c0c0c0'; TextOnAccent: '#ffffff'; Button: '#3a3a3a'; Panel: '#3a3a3a'; Accent: '#3e3e3e'; Border: '#191919'; BorderHot: '#2e6176'),
    (Name: 'Charcoal Dark Slate'; IsDark: True; Text: '#a3a3a3'; TextOnAccent: '#ffffff'; Button: '#3a3a3a'; Panel: '#3a3a3a'; Accent: '#1f1f1f'; Border: '#191919'; BorderHot: '#191919'),
    (Name: 'Cobalt XEMedia'; IsDark: True; Text: '#c0c0c0'; TextOnAccent: '#ffffff'; Button: '#121e32'; Panel: '#121e32'; Accent: '#0f2c54'; Border: '#a1a5ab'; BorderHot: '#a1a5ab'),
    (Name: 'Copper'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#ffffff'; Panel: '#ffffff'; Accent: '#e46b60'; Border: '#ffffff'; BorderHot: '#e46b60'),
    (Name: 'CopperDark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#2b2b2b'; Panel: '#2b2b2b'; Accent: '#e46b60'; Border: '#898989'; BorderHot: '#e46b60'),
    (Name: 'Coral'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#d86d00'; Panel: '#d86d00'; Accent: '#d86d00'; Border: '#d86d00'; BorderHot: '#d1d1d1'),
    (Name: 'Cyan Dusk'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#b4bac2'; Panel: '#b4bac2'; Accent: '#324a65'; Border: '#687e97'; BorderHot: '#687e97'),
    (Name: 'Cyan Night'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#b0b4bf'; Panel: '#b0b4bf'; Accent: '#323c62'; Border: '#687297'; BorderHot: '#687297'),
    (Name: 'Diamond'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#efeff0'; Panel: '#efeff0'; Accent: '#f5f5f5'; Border: '#c4c3c3'; BorderHot: '#c4c3c3'),
    (Name: 'Emerald'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#00a57d'; Panel: '#00a57d'; Accent: '#00a57d'; Border: '#00a57d'; BorderHot: '#cbcbc7'),
    (Name: 'Emerald Light Slate'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#e0e0e0'; Panel: '#e0e0e0'; Accent: '#87e168'; Border: '#9c9c9c'; BorderHot: '#9c9c9c'),
    (Name: 'Flat UI Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#e4e6e7'; Panel: '#e4e6e7'; Accent: '#3498da'; Border: '#e4e6e7'; BorderHot: '#3498da'),
    (Name: 'Glossy'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3d3d3d'; Panel: '#3d3d3d'; Accent: '#2f65a7'; Border: '#000000'; BorderHot: '#000000'),
    (Name: 'Glow'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#37bdbb'; Button: '#2e343c'; Panel: '#2e343c'; Accent: '#2d333b'; Border: '#1a1c1f'; BorderHot: '#1a1c1f'),
    (Name: 'Golden Graphite'; IsDark: True; Text: '#eaeaea'; TextOnAccent: '#ffffff'; Button: '#bb8900'; Panel: '#bb8900'; Accent: '#c6920f'; Border: '#5c3e04'; BorderHot: '#5c3e04'),
    (Name: 'Iceberg Classico'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#e4eaf1'; Panel: '#e4eaf1'; Accent: '#99c7ea'; Border: '#91a6c0'; BorderHot: '#91a6c0'),
    (Name: 'Jet'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#cee9f8'; Button: '#303030'; Panel: '#303030'; Accent: '#393939'; Border: '#585858'; BorderHot: '#585858'),
    (Name: 'Lavender Classico'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#eaeaee'; Panel: '#eaeaee'; Accent: '#a9c4e6'; Border: '#a1a1b4'; BorderHot: '#a1a1b4'),
    (Name: 'Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#d4e6f3'; Border: '#ababab'; BorderHot: '#a2c7e4'),
    (Name: 'Lucky Point'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#3f4c6a'; Panel: '#3f4c6a'; Accent: '#74b9c9'; Border: '#3f4c6a'; BorderHot: '#74b9c9'),
    (Name: 'Luna'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#bcd0e9'; Panel: '#bcd0e9'; Accent: '#ffd355'; Border: '#99b5de'; BorderHot: '#99b5de'),
    (Name: 'Material Oxford Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#5f6a72'; Panel: '#5f6a72'; Accent: '#00a1a1'; Border: '#5f6a72'; BorderHot: '#00a1a1'),
    (Name: 'Material Oxford Blue SE'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#5f6a72'; Panel: '#5f6a72'; Accent: '#0a7fbf'; Border: '#5f6a72'; BorderHot: '#0a7fbf'),
    (Name: 'Material Pattens Blue'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#e6ecf2'; Panel: '#e6ecf2'; Accent: '#e6ecf2'; Border: '#c4d3df'; BorderHot: '#18a1e9'),
    (Name: 'Metropolis UI Black'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#1a1a1a'; Panel: '#1a1a1a'; Accent: '#1373a9'; Border: '#f8f8f8'; BorderHot: '#f8f8f8'),
    (Name: 'Metropolis UI Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#1373a9'; Panel: '#1373a9'; Accent: '#e86625'; Border: '#f8f8f8'; BorderHot: '#f8f8f8'),
    (Name: 'Metropolis UI Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#1a1a1a'; Panel: '#1a1a1a'; Accent: '#5e5e5e'; Border: '#f8f8f8'; BorderHot: '#f8f8f8'),
    (Name: 'Metropolis UI Green'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#096c37'; Panel: '#096c37'; Accent: '#247c4d'; Border: '#ffffff'; BorderHot: '#ffffff'),
    (Name: 'Obsidian'; IsDark: True; Text: '#000000'; TextOnAccent: '#000000'; Button: '#cfd2d7'; Panel: '#cfd2d7'; Accent: '#ffd24e'; Border: '#2f2f2f'; BorderHot: '#2f2f2f'),
    (Name: 'Onyx Blue'; IsDark: True; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#adb0b4'; Panel: '#adb0b4'; Accent: '#42729a'; Border: '#adb0b4'; BorderHot: '#42729a'),
    (Name: 'Puerto Rico'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#44beb0'; Panel: '#44beb0'; Accent: '#52cfc0'; Border: '#44beb0'; BorderHot: '#52cfc0'),
    (Name: 'Radiant'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#00b8b0'; Panel: '#00b8b0'; Accent: '#19bfb7'; Border: '#00b8b0'; BorderHot: '#19bfb7'),
    (Name: 'Ruby Graphite'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#bb0d00'; Panel: '#bb0d00'; Accent: '#cc1e15'; Border: '#5c0404'; BorderHot: '#5c0404'),
    (Name: 'Sapphire Kamri'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#c1d9e7'; Panel: '#c1d9e7'; Accent: '#fa946b'; Border: '#6d9dbf'; BorderHot: '#a57b6c'),
    (Name: 'Silver'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#dce0e6'; Panel: '#dce0e6'; Accent: '#ffd24e'; Border: '#b9bec8'; BorderHot: '#b9bec8'),
    (Name: 'Sky'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#efefef'; Panel: '#efefef'; Accent: '#acdbef'; Border: '#bebebe'; BorderHot: '#bebebe'),
    (Name: 'Slate Classico'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#ebebeb'; Panel: '#ebebeb'; Accent: '#99c7ea'; Border: '#a8a8a8'; BorderHot: '#6692be'),
    (Name: 'Smokey Quartz Kamri'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#dbdbdb'; Panel: '#dbdbdb'; Accent: '#f39772'; Border: '#9f9f9f'; BorderHot: '#9f9f9f'),
    (Name: 'Stellar'; IsDark: True; Text: '#3e629a'; TextOnAccent: '#3e629a'; Button: '#fcfcfc'; Panel: '#fcfcfc'; Accent: '#ffffff'; Border: '#fcfcfc'; BorderHot: '#fcfcfc'),
    (Name: 'Stellar Dark'; IsDark: True; Text: '#3e629a'; TextOnAccent: '#3e629a'; Button: '#fcfcfc'; Panel: '#fcfcfc'; Accent: '#ffffff'; Border: '#fcfcfc'; BorderHot: '#fcfcfc'),
    (Name: 'Sterling'; IsDark: False; Text: '#000000'; TextOnAccent: '#527593'; Button: '#f9fafc'; Panel: '#f9fafc'; Accent: '#eef6fb'; Border: '#dde1e4'; BorderHot: '#dde1e4'),
    (Name: 'Tablet Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#3d4a79'; Panel: '#3d4a79'; Accent: '#1abc9c'; Border: '#3d4a79'; BorderHot: '#1abc9c'),
    (Name: 'TabletDark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#3d4a79'; Panel: '#3d4a79'; Accent: '#1abc9c'; Border: '#3d4a79'; BorderHot: '#1abc9c'),
    (Name: 'Tablet Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#ffffff'; Panel: '#ffffff'; Accent: '#3d84dd'; Border: '#3d84dd'; BorderHot: '#3d84dd'),
    (Name: 'Turquoise Gray'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#ededed'; Panel: '#ededed'; Accent: '#28c0e9'; Border: '#d3d3d3'; BorderHot: '#019ac4'),
    (Name: 'Vapor'; IsDark: True; Text: '#000000'; TextOnAccent: '#000000'; Button: '#89dcc8'; Panel: '#89dcc8'; Accent: '#7cc6b4'; Border: '#89dcc8'; BorderHot: '#7cc6b4'),
    (Name: 'Wedgewood Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#f5f5f6'; Panel: '#f5f5f6'; Accent: '#5a7390'; Border: '#dfdfe1'; BorderHot: '#dfdfe1'),
    (Name: 'Windows10'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#cccccc'; Panel: '#cccccc'; Accent: '#cccccc'; Border: '#cccccc'; BorderHot: '#7a7a7a'),
    (Name: 'Windows10 BlackPearl'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#36424a'; Panel: '#36424a'; Accent: '#36424a'; Border: '#36424a'; BorderHot: '#f36638'),
    (Name: 'Windows10 Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Windows10 Blue Whale'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#364762'; Panel: '#364762'; Accent: '#364762'; Border: '#364762'; BorderHot: '#0c96f2'),
    (Name: 'Windows10 Blue Whale LE'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#364762'; Panel: '#364762'; Accent: '#364762'; Border: '#364762'; BorderHot: '#0c96f2'),
    (Name: 'Windows10 Charcoal'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#303030'; Panel: '#303030'; Accent: '#2a2a2a'; Border: '#545454'; BorderHot: '#1c68a8'),
    (Name: 'Windows10 Clear Day'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#e5f0f6'; Panel: '#e5f0f6'; Accent: '#aed8f8'; Border: '#aed9f8'; BorderHot: '#67baed'),
    (Name: 'Windows10 Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#262626'; Panel: '#262626'; Accent: '#262626'; Border: '#262626'; BorderHot: '#7e7e7e'),
    (Name: 'Windows10 Green'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#055249'; Panel: '#055249'; Accent: '#055249'; Border: '#055249'; BorderHot: '#ffffff'),
    (Name: 'Windows10 Malibu'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#deecf0'; Panel: '#deecf0'; Accent: '#64c6da'; Border: '#d8e5e9'; BorderHot: '#64c6da'),
    (Name: 'Windows10 Purple'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#672d63'; Panel: '#672d63'; Accent: '#672d63'; Border: '#672d63'; BorderHot: '#ffffff'),
    (Name: 'Windows10 SlateGray'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#7daca8'; Button: '#2a353b'; Panel: '#2a353b'; Accent: '#2a353b'; Border: '#2a353b'; BorderHot: '#7daca8'),
    (Name: 'Windows11 MineShaft'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#000000'; Button: '#373737'; Panel: '#373737'; Accent: '#47b1e8'; Border: '#373737'; BorderHot: '#47b1e8'),
    (Name: 'Windows11 Modern Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#373737'; Panel: '#373737'; Accent: '#405560'; Border: '#434343'; BorderHot: '#4ab2e9'),
    (Name: 'Windows11 Modern Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#eef4f9'; Border: '#bbbbbb'; BorderHot: '#0067c0'),
    (Name: 'Windows11 Polar Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#4b5167'; Panel: '#4b5167'; Accent: '#0781e0'; Border: '#4b5167'; BorderHot: '#0781e0'),
    (Name: 'Windows11 Polar Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#c7d4e1'; Panel: '#c7d4e1'; Accent: '#a2d0fe'; Border: '#c7d4e1'; BorderHot: '#a2d0fe'),
    (Name: 'Windows11 White Smoke'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#1975c5'; Border: '#e9e9e9'; BorderHot: '#1975c5'),
    (Name: 'Zircon'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#e5e8e9'; Panel: '#e5e8e9'; Accent: '#a0d4de'; Border: '#e5e8e9'; BorderHot: '#a0d4de'),
    (Name: 'Zircon SE'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#e5e8e9'; Panel: '#e5e8e9'; Accent: '#a0d4de'; Border: '#e5e8e9'; BorderHot: '#a0d4de'),
    (Name: 'Windows11 Impressive Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'Windows11 Impressive Dark SE'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'Windows11 Impressive Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#cad4e6'; Panel: '#cad4e6'; Accent: '#5172ef'; Border: '#cad4e6'; BorderHot: '#5172ef'),
    (Name: 'Windows11 Impressive Light SE'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#cad4e6'; Panel: '#cad4e6'; Accent: '#5172ef'; Border: '#cad4e6'; BorderHot: '#5172ef'),
    (Name: 'Windows Modern'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#cccccc'; Panel: '#cccccc'; Accent: '#1681da'; Border: '#cccccc'; BorderHot: '#1681da'),
    (Name: 'Windows Modern Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#373737'; Panel: '#373737'; Accent: '#405560'; Border: '#434343'; BorderHot: '#4ab2e9'),
    (Name: 'Windows Modern Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#6aadec'; Border: '#084f8a'; BorderHot: '#6aadec'),
    (Name: 'Windows Modern Green'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#055249'; Panel: '#055249'; Accent: '#7cb2ab'; Border: '#055249'; BorderHot: '#7cb2ab'),
    (Name: 'Windows Modern Purple'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#672d63'; Panel: '#672d63'; Accent: '#b382af'; Border: '#672d63'; BorderHot: '#b382af'),
    (Name: 'Windows Modern SlateGray'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#2a353b'; Panel: '#2a353b'; Accent: '#7daca8'; Border: '#2a353b'; BorderHot: '#7daca8'),
    (Name: 'Windows Modern MountainMist'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#dadada'; Panel: '#dadada'; Accent: '#e1edf6'; Border: '#b4b4b4'; BorderHot: '#3a93dd'),
    (Name: 'CDE Frost: Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'CDE Frost: Teal'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'CDE: Golden Graphite'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'CDE Graphite: Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'CDE Graphite: Teal'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'CDE Impressive: Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'CDE Impressive: Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#cad4e6'; Panel: '#cad4e6'; Accent: '#5172ef'; Border: '#cad4e6'; BorderHot: '#5172ef'),
    (Name: 'CDE Modern: Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#3f506d'; Panel: '#3f506d'; Accent: '#5172ef'; Border: '#3f506d'; BorderHot: '#5172ef'),
    (Name: 'CDE Modern: Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#ffffff'; Button: '#cad4e6'; Panel: '#cad4e6'; Accent: '#5172ef'; Border: '#cad4e6'; BorderHot: '#5172ef'),
    (Name: 'Raize Frost : Blue'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Frost : Green'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Frost : Orange'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Frost : Purple'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Frost : Red'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Frost : Teal'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Frost : Yellow'; IsDark: False; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Blue'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Green'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Orange'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Purple'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Red'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Teal'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Raize Graphite : Yellow'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#084f8a'; Panel: '#084f8a'; Accent: '#084f8a'; Border: '#084f8a'; BorderHot: '#ffffff'),
    (Name: 'Win10IDE_Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#373737'; Panel: '#373737'; Accent: '#405560'; Border: '#434343'; BorderHot: '#4ab2e9'),
    (Name: 'Windows Designer Dark'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#373737'; Panel: '#373737'; Accent: '#405560'; Border: '#434343'; BorderHot: '#4ab2e9'),
    (Name: 'Windows Designer Dark Modern'; IsDark: True; Text: '#ffffff'; TextOnAccent: '#ffffff'; Button: '#373737'; Panel: '#373737'; Accent: '#405560'; Border: '#434343'; BorderHot: '#4ab2e9'),
    (Name: 'Win10IDE_Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#eef4f9'; Border: '#bbbbbb'; BorderHot: '#0067c0'),
    (Name: 'Windows Designer Light'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#eef4f9'; Border: '#bbbbbb'; BorderHot: '#0067c0'),
    (Name: 'Windows Designer Light Modern'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#eef4f9'; Border: '#bbbbbb'; BorderHot: '#0067c0'),
    (Name: 'Mountain_Mist'; IsDark: False; Text: '#000000'; TextOnAccent: '#000000'; Button: '#fdfdfd'; Panel: '#fdfdfd'; Accent: '#eef4f9'; Border: '#bbbbbb'; BorderHot: '#0067c0')
  );

implementation

uses
  Winapi.Windows,
  Vcl.Themes,
  Vcl.Forms;

function HelpChatColorToHex(const AColor: TColor): string;
var
  LRgb: Longint;
begin
  LRgb := ColorToRGB(AColor);
  Result := HelpChatRgbToHex(GetRValue(LRgb), GetGValue(LRgb), GetBValue(LRgb));
end;

function HelpChatActiveVclStyleName: string;
begin
  if TStyleManager.IsCustomStyleActive then
    Result := TStyleManager.ActiveStyle.Name
  else
    Result := '';
  if (Result = '') or (Result = 'Windows Designer') or (Result = 'Windows Designer Dark') or
     (Result = 'Windows Designer Modern') or (Result = 'Windows Designer Dark Modern') or
     (Result = 'Win10IDE_Dark') or (Result = 'Win10IDE_Light') or (Result = 'Mountain_Mist') then
    Result := 'Windows';
end;

function HelpChatFindVclStyleColors(const AStyleName: string; out AColors: THelpChatVclStyleColors): Boolean;
var
  I: Integer;
begin
  for I := Low(HELPCHAT_VCL_STYLE_TABLE) to High(HELPCHAT_VCL_STYLE_TABLE) do
    if SameText(HELPCHAT_VCL_STYLE_TABLE[I].Name, AStyleName) then
    begin
      AColors := HELPCHAT_VCL_STYLE_TABLE[I];
      Exit(True);
    end;
  AColors := Default(THelpChatVclStyleColors);
  Result := False;
end;

function HelpChatThemeFromVclStyle(const AStyleName: string): THelpChatTheme;
var
  LName, LWindow: string;
  LColors: THelpChatVclStyleColors;
  LIsActive: Boolean;
begin
  Result := Default(THelpChatTheme);
  LName := AStyleName;
  if LName = '' then
    LName := HelpChatActiveVclStyleName;
  Result.Name := LName;
  LIsActive := SameText(LName, HelpChatActiveVclStyleName);

  // Window colour of the style: the page background.
  if LIsActive and TStyleManager.IsCustomStyleActive then
    LWindow := HelpChatColorToHex(StyleServices.GetStyleColor(scWindow))
  else if LIsActive then
    LWindow := HelpChatColorToHex(clWindow)
  else
    LWindow := '';

  if HelpChatFindVclStyleColors(LName, LColors) then
  begin
    Result.IsDark := LColors.IsDark;
    Result.Surface := LColors.Panel;
    Result.Text := LColors.Text;
    Result.Border := LColors.Border;
    // Some styles have a pale hover colour and keep the brand colour on the hot
    // border ("Windows": #e0eef9 vs #0078d4): take the more saturated one.
    if HelpChatSaturation(LColors.BorderHot) > HelpChatSaturation(LColors.Accent) then
      Result.Accent := LColors.BorderHot
    else
      Result.Accent := LColors.Accent;
    Result.Background := LWindow;
    // No window colour, or one equal to the surface: bubbles need contrast.
    if (Result.Background = '') or SameText(Result.Background, Result.Surface) then
      if Result.IsDark then
        Result.Background := HelpChatBlend(Result.Surface, '#000000', 0.25)
      else
        Result.Background := HelpChatBlend(Result.Surface, '#000000', 0.04);
  end
  else
  begin
    // Unknown style: ask the style itself.
    Result.Background := LWindow;
    if Result.Background = '' then
      Result.Background := HelpChatColorToHex(StyleServices.GetSystemColor(clWindow));
    Result.Surface := HelpChatColorToHex(StyleServices.GetSystemColor(clBtnFace));
    Result.Text := HelpChatColorToHex(StyleServices.GetStyleFontColor(sfWindowTextNormal));
    Result.Border := HelpChatColorToHex(StyleServices.GetStyleColor(scBorder));
    Result.Accent := HelpChatColorToHex(StyleServices.GetSystemColor(clHighlight));
    Result.IsDark := HelpChatIsDarkColor(Result.Background);
  end;

  if Screen.MessageFont.Name <> '' then
    Result.FontFamily := '"' + Screen.MessageFont.Name + '", system-ui, sans-serif';
  Result.Complete;
end;

end.
