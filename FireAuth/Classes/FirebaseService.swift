import Firebase
import FirebaseAuth


private struct User {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}

private enum ServiceResult<Value> {
    case success(User?)
    case failure(String)
}

private protocol FirebaseServiceProtocol {
    func configureFirebase()
    func createUser(firstName: String, lastName: String, email: String, password: String, completion: @escaping (ServiceResult<Any>) -> Void)
    func login(email: String, password: String, completion: @escaping (ServiceResult<Any>) -> Void)
    func getData(completion: @escaping (ServiceResult<Any>) -> Void)
}

public class FirebaseService: FirebaseServiceProtocol {
    var onSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    
    func configureFirebase() {
        FirebaseApp.configure()
    }
    
    fileprivate func createUser(firstName: String, lastName: String, email: String, password: String, completion: @escaping (ServiceResult<Any>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if error != nil {
                self.onError?("Error creating user.")
                completion(.failure("Error creating user."))
            }
            else {
                if let uid = result?.user.uid {
                let dataBase = Firestore.firestore()
                    dataBase.collection("users").addDocument(data: ["firstName": firstName, "lastName": lastName, "uid": uid]) { error in
                        if error != nil {
                            self.onError?("Error saving user data.")
                            completion(.failure("Error saving user data."))
                        }
                        else {
                            self.onSuccess?()
                            completion(.success(nil))
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func login(email: String, password: String, completion: @escaping (ServiceResult<Any>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                self.onError?("Wrong email or pasword.")
                completion(.failure("Wrong email or pasword."))
            }
            else {
                self.onSuccess?()
                completion(.success(nil))
            }
        }
    }
    
    fileprivate func getData(completion: @escaping (ServiceResult<Any>) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { (snapshot, error) in
            if error == nil {
                if let snapshot = snapshot {

                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    for document in snapshot.documents {
                        let userUid = document["uid"] as? String ?? ""
                        if userUid == uid {
                            let firstName = document["firstName"] as? String ?? ""
                            let lastName = document["lastName"] as? String ?? ""
                            let email = document["email"] as? String ?? ""
                            let password = document["password"] as? String ?? ""
                            let user = User(firstName: firstName, lastName: lastName, email: email, password: password)
                            completion(.success(user))
                            self.onSuccess?()
                        }
                    }
                }
            }
            else {
                self.onError?("Something went wrong with user data fetching.")
                completion(.failure("Something went wrong with user data fetching."))
            }
        }
    }
}
