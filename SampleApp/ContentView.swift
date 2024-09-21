//
//  ContentView.swift
//
//  Created by Lightech on 5/20/21.
//

import SwiftUI
import SwiftGit2

let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
var localRepoLocation = documentURL.appendingPathComponent("BigMac")



struct ContentView: View {

    class VM : ObservableObject {
        @Published var isFetching: Bool = false
    }
    @StateObject var vm: ContentView.VM = ContentView.VM()
    @State var message = ""

    let remoteRepoLocation = "https://githubfast.com/sunknudsen/privacy-guides.git"

    init() {
        // git_libgit2_init()
        Repository.initialize_libgit2()
    }

    var body: some View {
        VStack {
            Button("Open test Git repo", action: testGitRepo)
            HStack{
                Button("Clone remote Git repo:\( vm.isFetching ? "Fetching" :"-" )", action: cloneGitRepo)
                ActivityIndicator(isAnimating: Binding(get: {
                    vm.isFetching
                }, set: { v in
                    vm.isFetching = v
                }), style: UIActivityIndicatorView.Style.medium)
            }
            Button(" remove Git repo", action: {
              try?  FileManager.default.removeItem(at: localRepoLocation)
            })

            Button("Create remote Git repo", action: {

                let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                localRepoLocation = documentURL.appendingPathComponent("BigMac")
            })
                VStack{
                    Text(message)
                    EditorTreeView()
                }
            
        }.padding(5)
    }

    
    func cloneGitRepo() {
        vm.isFetching = true
        Task.detached {
            let remote: URL = URL(string: remoteRepoLocation)!
            
            let repo = remoteRepoLocation.components(separatedBy: "/").last?.components(separatedBy: ".git").first ?? "repo"
          let repoURL =  URL(fileURLWithPath: localRepoLocation.absoluteString).appendingPathComponent(String(repo))
            let result = Repository.clone(from: remote, to: repoURL)
            await MainActor.run {
                self.vm.isFetching = false
            }
            switch result {
            case let .success(repo):
                let latestCommit = repo
                    .HEAD()
                    .flatMap {
                        repo.commit($0.oid)
                    }

                switch latestCommit {
                case let .success(commit):
                    await MainActor.run {
                        message = "Latest Commit: \(commit.message) by \(commit.author.name)"
                    }

                case let .failure(error):
                    await MainActor.run {
                        message = "Could not get commit: \(error)"
                    }
                }

            case let .failure(error):
                await MainActor.run {
                    message = "Could not clone repository: \(error)"
                }
            }
        }
        
    }

    func testGitRepo() {
        let result = Repository.at(localRepoLocation)
        switch result {
        case let .success(repo):
            let latestCommit = repo
                .HEAD()
                .flatMap {
                    repo.commit($0.oid)
                }

            switch latestCommit {
            case let .success(commit):
                message = "Latest Commit: \(commit.message) by \(commit.author.name)"

            case let .failure(error):
                message = "Could not get commit: \(error)"
            }

        case let .failure(error):
            message = "Could not open repository: \(error)"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
