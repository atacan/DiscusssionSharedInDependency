//
// https://github.com/atacan
// 20.05.24
	

import SwiftUI
import ComposableArchitecture
import Dependencies
import Combine

struct Something: Codable, Equatable, Sendable {
    var name: String
    
    init(name: String = "Name") {
        self.name = name
    }
}

extension PersistenceReaderKey where Self == FileStorageKey<Something> {
  static var something: Self {
      fileStorage(URL.documentsDirectory.appending(component: "something.json"))
  }
}

struct ApiClient: DependencyKey {
    var get: @Sendable () -> String
    
    static var liveValue: ApiClient {
        
        var cancellables = Set<AnyCancellable>()
        var myData = MyData()
        let myDataIsolated = LockIsolated(MyData())
        
        @Shared(.something) var something = .init()
        @Shared(.appStorage("anotherthing")) var anotherthing = ""
        
        $something.publisher.sink { completion in
            print("receiveCompletion: \(completion)")
        } receiveValue: { value in
            // is never called
            print("receiveValue: \(value)")
            myData.something = value
            myDataIsolated.withValue { $0.something = value }
        }
        .store(in: &cancellables)
        
        return Self(get: { [myData = myData] in // Otherwise: Reference to captured var 'myData' in concurrently-executing code
            print("myDataIsolated.value.something.name", myDataIsolated.value.something.name)
            print("myData.something.name", myData.something.name)
            // 👆 both always output default init value, even in app restart. does not fetch what's in the file.
            return myData.something.name
        })
    }
    
    struct MyData: Sendable {
        var something: Something
        
        init(something: Something = .init()) {
            self.something = something
        }
    }
}

extension DependencyValues {
    var api: ApiClient {
        get { self[ApiClient.self] }
        set { self[ApiClient.self] = newValue }
    }
}

@Reducer
public struct Content {
    @ObservableState
    public struct State: Equatable {
        @Shared(.something) var something = .init()
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case apiCall
    }
    
    @Dependency(\.api) var api
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .apiCall:
                print("api.get()", api.get())
                return .none
            case .onAppear:
                print("api.get()", api.get())
                // to look at the file
                print(URL.documentsDirectory.appending(component: "something.json"))
                return .none
                
            }
        }
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<Content>
    
    var body: some View {
        VStack {
            Text("Hello, world!")
            TextField("Type here…", text: $store.something.name)
            Button("Api call") {
                store.send(.apiCall)
            }
        }
        .padding()
        .onAppear(perform: {
            store.send(.onAppear)
        })
    }
}

#Preview {
    ContentView(store: Store(initialState: Content.State(), reducer: {
        Content()
    }))
}
