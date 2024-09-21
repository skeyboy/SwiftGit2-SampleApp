//
//  EditorTreeView.swift
//  SampleApp
//
//  Created by lee on 2024/9/20.
//

import SwiftUI
import UIKit
import Runestone
import TreeSitterAstroRunestone
import TreeSitterBashRunestone
import TreeSitterCPPRunestone
import TreeSitterCRunestone
import TreeSitterCSSRunestone
import TreeSitterCSharpRunestone
import TreeSitterCommentRunestone
import TreeSitterElixirRunestone
import TreeSitterElmRunestone
import TreeSitterGoRunestone
import TreeSitterHTMLRunestone
import TreeSitterHaskellRunestone
import TreeSitterJSDocRunestone
import TreeSitterJSON5Runestone
import TreeSitterJSONRunestone
import TreeSitterJavaRunestone
import TreeSitterJavaScriptRunestone
import TreeSitterJuliaRunestone
import TreeSitterLaTeXRunestone
import TreeSitterLuaRunestone
import TreeSitterMarkdownInlineRunestone
import TreeSitterMarkdownRunestone
import TreeSitterOCamlRunestone
import TreeSitterPHPRunestone
import TreeSitterPerlRunestone
import TreeSitterPythonRunestone
import TreeSitterRRunestone
import TreeSitterRegexRunestone
import TreeSitterRubyRunestone
import TreeSitterRustRunestone
import TreeSitterSCSSRunestone
import TreeSitterSQLRunestone
import TreeSitterSvelteRunestone
import TreeSitterSwiftRunestone
import TreeSitterTOMLRunestone
import TreeSitterTSXRunestone
import TreeSitterTypeScriptRunestone
import TreeSitterYAMLRunestone

struct EditorImageView: UIViewRepresentable {
    @State var fileURI: String
    func makeUIView(context: Context) -> UIImageView {
        let imageView =  UIImageView()
        imageView.image = UIImage(contentsOfFile: fileURI)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        
    }
    
    typealias UIViewType = UIImageView
    
    
}
@propertyWrapper
struct MyBinding<T> {
    var wrappedValue:T{
        get {
            getter()
        }
        set {
            
        }
    }
    var getter: ()->T
    var setter: (T,T)->Void
    init(getter: @escaping () -> T, setter: @escaping (T, T) -> Void) {
        self.getter = getter
        self.setter = setter
    }
    //    init(wrappedValue:T,get getter: @escaping () -> T, set setter: @escaping (T, T) -> Void) {
    //        self.getter = getter
    //        self.setter = setter
    //
    //    }
    //    init( getter:@escaping ()->T, setter: @escaping (T)->Void) {
    //        self.getter = getter
    //        self.setter = setter
    //    }
}


@available(iOS 13.0, *)
public struct ActivityIndicator: UIViewRepresentable {
    
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    public func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    public func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct EditorView : View {
    @State var isRendering: Bool = true
    var fileURI: String
    @StateObject var vm: VM = VM()
    var body: some View {
        @State var isAnimating = vm.isParsing
        GeometryReader { geometry in
            ZStack {
                if  fileURI.isImage {
                    EditorImageView(fileURI: fileURI)
                }  else {
                    _EditorView(vm: vm,
                                fileURI: fileURI).opacity(self.vm.isParsing ? 0 : 1)
                }
                VStack(alignment: .center) {
                    ActivityIndicator(isAnimating: Binding(get: {
                        vm.isParsing
                    }, set: { v in
                        vm.isParsing = v
                    }), style: UIActivityIndicatorView.Style.medium)
                    Text(NSLocalizedString("loading", comment: "加载中…"))
                }.frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.secondary.colorInvert())
                    .foregroundColor(Color.primary)
                    .cornerRadius(5)
                    .opacity(self.vm.isParsing ? 1 : 0)
            }
        }
    }
    
    struct _EditorView: UIViewRepresentable {
        var vm: VM
        var fileURI: String
        func makeUIView(context: Context) -> Runestone.TextView {
            let textView = context.coordinator.textView
            textView.showTabs = true
            textView.showSpaces = true
            textView.showPageGuide = true
            textView.showLineNumbers = true
            context.coordinator.fileURI = fileURI
            return textView
        }
        
        func updateUIView(_ uiView: UIViewType, context: Context) {
            
        }
        
        func makeCoordinator() -> VM {
            vm
        }
        
        typealias UIViewType = TextView
        typealias Coordinator = VM
    }
    
    @MainActor class VM : ObservableObject {
        @Published var isParsing: Bool = false
        var textView: TextView = .init()
        @MainActor var fileURI: String  = "" {
            willSet  {
                if newValue != self.fileURI && newValue != "" {
                    DispatchQueue.main.async {
                        self.isParsing = true
                    }
                }
            }
            didSet{
                
                
                if let text = try? String(contentsOfFile: fileURI) {
                    Task.detached(priority: .userInitiated) { [weak self] in
                        guard let self = self else {
                            await MainActor.run { [weak self] in
                                self?.isParsing = false
                            }
                            return
                        }
                        
                        await self.textView.setState(
                            TextViewState(text: text,
                                          language: self.detectLangauge(url: self.fileURI)))
                        await MainActor.run { [weak self] in
                            self?.isParsing = false
                        }
                    }
                    
                }
                
            }
        }
        
        private func detectLangauge(url: String) -> TreeSitterLanguage {
            if url.hasSuffix(".astro") {
                return .astro
            } else if url.hasSuffix(".bash") {
                return .bash
            } else if url.hasSuffix(".c") || url.hasSuffix(".h") {
                return .c
            } else if url.hasSuffix(".cpp") || url.hasSuffix(".hpp") {
                return .cpp
            } else if url.hasSuffix(".cs") {
                return .cSharp
            } else if url.hasSuffix(".css") {
                return .css
            } else if url.hasSuffix(".ex") {
                return .elixir
            } else if url.hasSuffix(".elm") {
                return .elm
            } else if url.hasSuffix(".go") {
                return .go
            } else if url.hasSuffix(".hs") {
                return .haskell
            } else if url.hasSuffix(".html") {
                return .html
            } else if url.hasSuffix(".java") {
                return .java
            } else if url.hasSuffix(".js") {
                return .javaScript
            } else if url.hasSuffix(".json5") {
                return .json5
            } else if url.hasSuffix(".json") {
                return .json
            } else if url.hasSuffix(".jl") {
                return .julia
            } else if url.hasSuffix(".tex") {
                return .latex
            } else if url.hasSuffix(".lua") {
                return .lua
            } else if url.hasSuffix(".md") {
                return .markdown
            } else if url.hasSuffix(".ml") {
                return .ocaml
            } else if url.hasSuffix(".pl") {
                return .perl
            } else if url.hasSuffix(".php") {
                return .php
            } else if url.hasSuffix(".py") {
                return .python
            } else if url.hasSuffix(".regex") {
                return .regex
            } else if url.hasSuffix(".r") {
                return .r
            } else if url.hasSuffix(".rb") {
                return .ruby
            } else if url.hasSuffix(".rs") {
                return .rust
            } else if url.hasSuffix(".scss") {
                return .scss
            } else if url.hasSuffix(".sql") {
                return .sql
            } else if url.hasSuffix(".svelte") {
                return .svelte
            } else if url.hasSuffix(".swift") {
                return .swift
            } else if url.hasSuffix(".toml") {
                return .toml
            } else if url.hasSuffix(".tsx") {
                return .tsx
            } else if url.hasSuffix(".ts") {
                return .typeScript
            } else if url.hasSuffix(".yaml") {
                return .yaml
            }
            return .comment
        }
        
    }
    
}

//
//struct EidtorViewModifier: ViewModifier {
//    typealias Body = EditorView
//
//    @State var isRendering = false
//    func body(content: EditorView) -> some View {
//
//        content
//            .padding()
//            .background(.quaternary, in: Capsule())
//    }
//}
//
//extension EditorView {
//
//}

#Preview {
    Text("Hello, world!")
    //.modifier(EidtorViewModifier())
}
class StackVM {
    var stack:[String] = []
}
class TreeItem: Identifiable, ObservableObject {
    
    let Id = UUID()
    let name: String
    var isExpanded = false
    var children: [TreeItem] = [] //for subentries
    var path : String
    init(path: String = [FileManager.DocumnetsDirectory(), "BigMac" ].joined(separator: "/")) {
        self.path = path
        self.name = String(path.split(separator: "/").last ?? "")
        self.children = FileManager.shallowSearchAllFiles(folderPath: path)?.map({ item in
            TreeItem(path: [path, item].joined(separator: "/"))
        }) ?? []
    }
    
}


struct OtherTreeItemView: View {
    var item: TreeItem
    var body: some View {
        NavigationView {
            if item.children.isEmpty {
                NavigationLink {
                    //                        TreeItemView(item: item)
                } label: {
                    Text(item.name)
                }
                
            } else {
                List(item.children, id: \.id) { it in
                    NavigationLink {
                        TreeItemView(item: item)
                    } label: {
                        Text(item.name)
                    }
                }.navigationTitle(item.name)
            }
        }
    }
}


struct TreeItemView: View {
    var item: TreeItem
    @State var isExpanded = true
    @State var isRendering = false
    func image(filePath: String) -> some View {
        return ScrollView {
            if let img = UIImage(contentsOfFile: filePath) {
                Image(uiImage: img).aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "camera")
                    .font(.system(size: 64))
                    .aspectRatio(contentMode: .fit)
            }
        }
        
    }
    
    var body: some View {
        ScrollView {
            Group {
                if !item.children.isEmpty {
                    ForEach(item.children) { child in
                        if (child.children.isEmpty){
                            NavigationLink(child.name) {
                                if !child.children.isEmpty {
                                    Text(child.name)
                                } else {
                                    if child.path.split(separator: ".").last == "png" {
                                        image(filePath: child.path)
                                    } else {
                                        
                                        EditorView(fileURI: child.path)
                                        
                                    }
                                }
                            }
                        }else{
                            NavigationLink(child.name) {
                                TreeItemView(item: child)
                            }
                        }
                        
                    }
                } else {
                    NavigationLink(item.name) {
                        Text(item.name)
                    }
                }
            }
        }
    }
}


struct EditorTreeView: View {
    
    @State var content:[TreeItem] = [] //initialize the content var
    
    var body: some View {
        Button("Show"){
            content = [TreeItem()]
        }
        NavigationView {
            ForEach(content, id: \.Id){item in
                ScrollView {
                    NavigationLink(item.name) {
                        if !item.children.isEmpty && item.path.split(separator: ".").count == 1 {
                            TreeItemView(item: item)
                        } else {
                            EditorView(fileURI: item.path)
                            
                        }
                    }
                }
            }
        }
        
    }
}

#Preview {
    EditorTreeView()
}
