module TextDocument = struct
  type uri =
    { scheme : string
    ; fsPath : string
    }

  type event = { uri : uri }
end

module Folder = struct
  type t =
    { uri : TextDocument.uri
    ; index : int
    ; name : string
    }
end

module WorkspaceConfiguration = struct
  type t

  external get' : t -> string -> Js.Json.t Js.Nullable.t = "get" [@@bs.send]

  let get workspaceConfig key = get' workspaceConfig key |> Js.Nullable.toOption

  type configurationTarget =
    | Global [@bs.as 1]
    | Workspace [@bs.as 2]
    | WorkspaceFolder
  [@@bs.deriving { jsConverter = newType }]

  external update :
    t -> string -> Js.Json.t -> abs_configurationTarget -> unit Promise.t
    = "update"
    [@@bs.send]
end

module Workspace = struct
  type workspaceFoldersChangeEvent =
    { added : Folder.t array
    ; removed : Folder.t array
    }

  external _name : string Js.Nullable.t = "name"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]

  let name () = Js.Nullable.toOption _name

  external _workspaceFolders : Folder.t array Js.Nullable.t = "workspaceFolders"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]

  let workspaceFolders () =
    Js.Nullable.toOption _workspaceFolders |. Belt.Option.getWithDefault [||]

  external onDidOpenTextDocument : (TextDocument.event -> unit) -> unit
    = "onDidOpenTextDocument"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]

  external getWorkspaceFolder : TextDocument.uri -> Folder.t option
    = "getWorkspaceFolder"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]

  external onDidChangeWorkspaceFolders :
    (workspaceFoldersChangeEvent -> unit) -> unit
    = "onDidChangeWorkspaceFolders"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]

  external textDocuments : TextDocument.event array = "textDocuments"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]

  external getConfiguration : string -> WorkspaceConfiguration.t
    = "getConfiguration"
    [@@bs.module "vscode"] [@@bs.scope "workspace"]
end

module Window = struct
  module QuickPickItem = struct
    type t

    external create :
         ?alwaysShow:bool
      -> ?description:string
      -> ?detail:string
      -> ?picked:bool
      -> label:string
      -> unit
      -> t = ""
      [@@bs.obj]
  end

  module QuickPickOptions = struct
    type t = < canPickMany : bool > Js.t

    external make : ?canPickMany:bool -> ?placeHolder:string -> unit -> t = ""
      [@@bs.obj]
  end

  module MessageItem = struct
    type t

    external create : ?title:string -> unit -> t = "" [@@bs.obj]
  end

  external showQuickPick' :
    string array -> QuickPickOptions.t -> string Js.Nullable.t Promise.t
    = "showQuickPick"
    [@@bs.module "vscode"] [@@bs.scope "window"]

  let showQuickPick choices quickPickOptions =
    showQuickPick' choices quickPickOptions
    |> Promise.map (fun choice -> choice |> Js.Nullable.toOption)

  external _showQuickPickItems :
       QuickPickItem.t array
    -> QuickPickOptions.t
    -> QuickPickItem.t Js.Nullable.t Promise.t = "showQuickPick"
    [@@bs.module "vscode"] [@@bs.scope "window"]

  let showQuickPickItems choices options =
    _showQuickPickItems (Array.of_list (List.map fst choices)) options
    |> Promise.map (fun choice ->
           choice |> Js.Nullable.toOption
           |. Belt.Option.map (fun q -> List.assq q choices))

  external showInformationMessage : string -> unit Promise.t
    = "showInformationMessage"
    [@@bs.module "vscode"] [@@bs.scope "window"]

  external _showInformationMessage' :
    string -> MessageItem.t array -> MessageItem.t Js.Nullable.t Promise.t
    = "showInformationMessage"
    [@@bs.module "vscode"] [@@bs.scope "window"] [@@bs.variadic]

  let showInformationMessage' msg choices =
    let choices =
      List.map
        (fun (title, choice) -> (MessageItem.create ~title (), choice))
        choices
    in
    _showInformationMessage' msg (choices |> List.map fst |> Array.of_list)
    |> Promise.map (fun choice ->
           choice |> Js.Nullable.toOption
           |. Belt.Option.map (fun q -> List.assq q choices))

  external showErrorMessage : string -> 'a Promise.t = "showErrorMessage"
    [@@bs.module "vscode"] [@@bs.scope "window"]

  external showWarningMessage' : string -> 'a Promise.t = "showErrorMessage"
    [@@bs.module "vscode"] [@@bs.scope "window"]

  let showWarningMessage m =
    showWarningMessage' m |> Js.Promise.then_ (fun _ -> Js.Promise.resolve ())

  type rangeEdge = { character : int }

  type range =
    { start : rangeEdge
    ; end_ : rangeEdge [@bs.as "end"]
    }

  type line = { range : range }

  type document =
    { getText : unit -> string
    ; lineAt : int -> line
    ; lineCount : int
    ; fileName : string
    }

  type activeTextEditor = { document : document }

  external activeTextEditor : activeTextEditor option = "activeTextEditor"
    [@@bs.module "vscode"] [@@bs.scope "window"] [@@bs.val]

  type location =
    | SourceControl [@bs.as 1]
    | Window [@bs.as 10]
    | Notification [@bs.as 15]
  [@@bs.deriving { jsConverter = newType }]

  type withProgressConfig = < title : string ; location : abs_location > Js.t

  type progress = { report : (< increment : int > Js.t -> unit[@bs]) }

  external withProgress :
       withProgressConfig
    -> (progress -> ('a, 'b) result Promise.t)
    -> ('a, 'b) result Promise.t = "withProgress"
    [@@bs.module "vscode"] [@@bs.scope "window"]
end

type memento

module Commands = struct
  external get : filterInternal:bool -> string array Promise.t = "getCommands"
    [@@bs.module "vscode"] [@@bs.scope "commands"]

  external register : command:string -> handler:(unit -> unit) -> unit
    = "registerCommand"
    [@@bs.module "vscode"] [@@bs.scope "commands"]

  external _executeCommand :
    command:string -> args:'a list -> unit Js.Nullable.t Promise.t
    = "executeCommand"
    [@@bs.module "vscode"] [@@bs.scope "commands"]

  let executeCommand ~command ~args =
    _executeCommand ~command ~args
    |> Promise.then_ (fun _ -> Promise.resolve ())
end

module ExtensionContext = struct
  type disposable = { dispose : (unit -> unit[@bs]) }

  type t =
    { extensionPath : string
    ; globalState : memento
    ; globalStoragePath : string
    ; logPath : string
    ; storagePath : string option
    ; subscriptions : disposable array
    ; workspaceState : memento
    ; asAbsolutePath : string -> string
    }
end

module Languages = struct
  type documentSelector =
    { scheme : string
    ; language : string
    }

  external registerDocumentFormattingEditProvider :
    documentSelector -> 'a -> unit = "registerDocumentFormattingEditProvider"
    [@@bs.module "vscode"] [@@bs.scope "languages"]
end

module Range = struct
  type t

  external create : int -> int -> int -> int -> t = "Range"
    [@@bs.module "vscode"] [@@bs.new]
end

module TextEdit = struct
  type t

  external replace : Range.t -> string -> t = "replace"
    [@@bs.module "vscode"] [@@bs.scope "TextEdit"]
end

module LanguageClient = struct
  type documentSelectorItem =
    { scheme : string
    ; language : string
    }

  type clientOptions = { documentSelector : documentSelectorItem array }

  type processOptions = { env : string Js.Dict.t }

  type serverOptions =
    { command : string
    ; args : string array
    ; options : processOptions
    }

  type t =
    { start : (unit -> unit[@bs])
    ; stop : (unit -> unit[@bs])
    }

  external make :
       id:string
    -> name:string
    -> serverOptions:serverOptions
    -> clientOptions:clientOptions
    -> t = "LanguageClient"
    [@@bs.new] [@@bs.module "vscode-languageclient"]
end
