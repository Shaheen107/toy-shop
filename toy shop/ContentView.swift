

import SwiftUI

// MARK: - Models

struct Toy: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var category: String
    var price: Double
    var quantity: Int
    var description: String
    
    static func == (lhs: Toy, rhs: Toy) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Customer: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var contactInfo: String
    var address: String
    var orderHistory: [Order] = []
    
    static func == (lhs: Customer, rhs: Customer) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Order: Identifiable, Codable, Equatable {
    var id = UUID()
    var toyName: String
    var quantity: Int
    var totalPrice: Double
    var customerName: String
    var orderDate: Date
    var status: String
    var paymentStatus: String
    
    static func == (lhs: Order, rhs: Order) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Managers

class ToyManager: ObservableObject {
    @Published var toys: [Toy] = [] {
        didSet {
            saveToys()
        }
    }
    
    init() {
        loadToys()
    }
    
    func addToy(_ toy: Toy) {
        toys.append(toy)
    }
    
    func updateToy(_ toy: Toy) {
        if let index = toys.firstIndex(where: { $0.id == toy.id }) {
            toys[index] = toy
        }
    }
    
    func deleteToy(at offsets: IndexSet) {
        toys.remove(atOffsets: offsets)
    }
    
    private func loadToys() {
        if let data = UserDefaults.standard.data(forKey: "toys"),
           let decoded = try? JSONDecoder().decode([Toy].self, from: data) {
            toys = decoded
        }
    }
    
    private func saveToys() {
        if let encoded = try? JSONEncoder().encode(toys) {
            UserDefaults.standard.set(encoded, forKey: "toys")
        }
    }
}

class CustomerManager: ObservableObject {
    @Published var customers: [Customer] = [] {
        didSet {
            saveCustomers()
        }
    }
    
    init() {
        loadCustomers()
    }
    
    func addCustomer(_ customer: Customer) {
        customers.append(customer)
    }
    
    func updateCustomer(_ customer: Customer) {
        if let index = customers.firstIndex(where: { $0.id == customer.id }) {
            customers[index] = customer
        }
    }
    
    func deleteCustomer(at offsets: IndexSet) {
        customers.remove(atOffsets: offsets)
    }
    
    private func loadCustomers() {
        if let data = UserDefaults.standard.data(forKey: "customers"),
           let decoded = try? JSONDecoder().decode([Customer].self, from: data) {
            customers = decoded
        }
    }
    
    private func saveCustomers() {
        if let encoded = try? JSONEncoder().encode(customers) {
            UserDefaults.standard.set(encoded, forKey: "customers")
        }
    }
}

class OrderManager: ObservableObject {
    @Published var orders: [Order] = [] {
        didSet {
            saveOrders()
        }
    }
    
    init() {
        loadOrders()
    }
    
    func addOrder(_ order: Order) {
        orders.append(order)
    }
    
    func updateOrder(_ order: Order) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
        }
    }
    
    func deleteOrder(at offsets: IndexSet) {
        orders.remove(atOffsets: offsets)
    }
    
    private func loadOrders() {
        if let data = UserDefaults.standard.data(forKey: "orders"),
           let decoded = try? JSONDecoder().decode([Order].self, from: data) {
            orders = decoded
        }
    }
    
    private func saveOrders() {
        if let encoded = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encoded, forKey: "orders")
        }
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var toyManager = ToyManager()
    @StateObject private var customerManager = CustomerManager()
    @StateObject private var orderManager = OrderManager()
    
    var body: some View {
        TabView {
            ToyInventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "cube.box.fill")
                }
                .environmentObject(toyManager)
            
            CustomerListView()
                .tabItem {
                    Label("Customers", systemImage: "person.3.fill")
                }
                .environmentObject(customerManager)
                .environmentObject(orderManager)
            
            OrderListView()
                .tabItem {
                    Label("Orders", systemImage: "cart.fill")
                }
                .environmentObject(orderManager)
                .environmentObject(customerManager)
        }
        .accentColor(.blue) // Custom accent color
    }
}

struct ToyInventoryView: View {
    @EnvironmentObject var toyManager: ToyManager
    @State private var showingAddToyView = false
    @State private var toyToEdit: Toy?
    @State private var showDeleteConfirmation = false
    @State private var toyToDelete: Toy?

    var body: some View {
        NavigationView {
            List {
                ForEach(toyManager.toys) { toy in
                    NavigationLink(destination: EditToyView(toy: binding(for: toy))) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(toy.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(toy.category)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text("$\(toy.price, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Quantity: \(toy.quantity)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "cube.box.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .shadow(color: .gray, radius: 2, x: 1, y: 1)
                    }
                    .contextMenu {
                        Button("Edit") {
                            toyToEdit = toy
                        }
                        Button("Delete", role: .destructive) {
                            toyToDelete = toy
                            showDeleteConfirmation = true
                        }
                    }
                }
                .onDelete(perform: toyManager.deleteToy)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Toy Inventory")
            .navigationBarItems(trailing: Button(action: {
                showingAddToyView = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
            })
            .sheet(isPresented: $showingAddToyView) {
                AddToyView()
                    .environmentObject(toyManager)
            }
            .sheet(item: $toyToEdit) { toy in
                EditToyView(toy: binding(for: toy))
                    .environmentObject(toyManager)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this toy? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let toy = toyToDelete, let index = toyManager.toys.firstIndex(of: toy) {
                            toyManager.toys.remove(at: index)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func binding(for toy: Toy) -> Binding<Toy> {
        guard let index = toyManager.toys.firstIndex(where: { $0.id == toy.id }) else {
            fatalError("Toy not found")
        }
        return $toyManager.toys[index]
    }
}

struct AddToyView: View {
    @EnvironmentObject var toyManager: ToyManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var category = ""
    @State private var price = ""
    @State private var quantity = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Toy Details")) {
                    TextField("Name", text: $name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Category", text: $category)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Description", text: $description)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                }
            }
            .navigationTitle("Add Toy")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                guard let toyPrice = Double(price), let toyQuantity = Int(quantity) else { return }
                let newToy = Toy(name: name, category: category, price: toyPrice, quantity: toyQuantity, description: description)
                toyManager.addToy(newToy)
                presentationMode.wrappedValue.dismiss()
            }.disabled(name.isEmpty || category.isEmpty || price.isEmpty || quantity.isEmpty))
        }
    }
}

struct EditToyView: View {
    @Binding var toy: Toy
    @EnvironmentObject var toyManager: ToyManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Toy Details")) {
                TextField("Name", text: $toy.name)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Category", text: $toy.category)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Price", value: $toy.price, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Quantity", value: $toy.quantity, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Description", text: $toy.description)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            }
        }
        .navigationTitle("Edit Toy")
        .navigationBarItems(trailing: Button("Save") {
            presentationMode.wrappedValue.dismiss()
        }.disabled(toy.name.isEmpty || toy.category.isEmpty || toy.price == 0.0 || toy.quantity == 0))
    }
}

struct CustomerListView: View {
    @EnvironmentObject var customerManager: CustomerManager
    @State private var showingAddCustomerView = false
    @State private var customerToEdit: Customer?
    @State private var showDeleteConfirmation = false
    @State private var customerToDelete: Customer?

    var body: some View {
        NavigationView {
            List {
                ForEach(customerManager.customers) { customer in
                    NavigationLink(destination: EditCustomerView(customer: binding(for: customer))) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(customer.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(customer.contactInfo)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(customer.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .shadow(color: .gray, radius: 2, x: 1, y: 1)
                    }
                    .contextMenu {
                        Button("Edit") {
                            customerToEdit = customer
                        }
                        Button("Delete", role: .destructive) {
                            customerToDelete = customer
                            showDeleteConfirmation = true
                        }
                    }
                }
                .onDelete(perform: handleDelete)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Customers")
            .navigationBarItems(trailing: Button(action: {
                showingAddCustomerView = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
            })
            .sheet(isPresented: $showingAddCustomerView) {
                AddCustomerView()
                    .environmentObject(customerManager)
            }
            .sheet(item: $customerToEdit) { customer in
                EditCustomerView(customer: binding(for: customer))
                    .environmentObject(customerManager)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this customer? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let customer = customerToDelete, let index = customerManager.customers.firstIndex(of: customer) {
                            customerManager.customers.remove(at: index)
                        }
                        showDeleteConfirmation = false
                    },
                    secondaryButton: .cancel {
                        showDeleteConfirmation = false
                    }
                )
            }
        }
    }
    
    private func binding(for customer: Customer) -> Binding<Customer> {
        guard let index = customerManager.customers.firstIndex(where: { $0.id == customer.id }) else {
            fatalError("Customer not found")
        }
        return $customerManager.customers[index]
    }

    private func handleDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            customerToDelete = customerManager.customers[index]
            showDeleteConfirmation = true
        }
    }
}

struct AddCustomerView: View {
    @EnvironmentObject var customerManager: CustomerManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var contactInfo = ""
    @State private var address = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customer Details")) {
                    TextField("Name", text: $name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Contact Info", text: $contactInfo)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Address", text: $address)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                }
            }
            .navigationTitle("Add Customer")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                let newCustomer = Customer(name: name, contactInfo: contactInfo, address: address)
                customerManager.addCustomer(newCustomer)
                presentationMode.wrappedValue.dismiss()
            }.disabled(name.isEmpty || contactInfo.isEmpty || address.isEmpty))
        }
    }
}

struct EditCustomerView: View {
    @Binding var customer: Customer
    @EnvironmentObject var customerManager: CustomerManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Customer Details")) {
                TextField("Name", text: $customer.name)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Contact Info", text: $customer.contactInfo)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Address", text: $customer.address)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            }
        }
        .navigationTitle("Edit Customer")
        .navigationBarItems(trailing: Button("Save") {
            presentationMode.wrappedValue.dismiss()
        }.disabled(customer.name.isEmpty || customer.contactInfo.isEmpty || customer.address.isEmpty))
    }
}

struct OrderListView: View {
    @EnvironmentObject var orderManager: OrderManager
    @EnvironmentObject var customerManager: CustomerManager
    @State private var showingAddOrderView = false
    @State private var orderToEdit: Order?
    @State private var showDeleteConfirmation = false
    @State private var orderToDelete: Order?

    var body: some View {
        NavigationView {
            List {
                ForEach(orderManager.orders) { order in
                    NavigationLink(destination: EditOrderView(order: binding(for: order))) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(order.toyName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                HStack {
                                    Text("Total: $\(order.totalPrice, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Quantity: \(order.quantity)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("Customer: \(order.customerName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(order.orderDate, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "cart.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .shadow(color: .gray, radius: 2, x: 1, y: 1)
                    }
                    .contextMenu {
                        Button("Edit") {
                            orderToEdit = order
                        }
                        Button("Delete", role: .destructive) {
                            orderToDelete = order
                            showDeleteConfirmation = true
                        }
                    }
                }
                .onDelete(perform: handleDelete)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Orders")
            .navigationBarItems(trailing: Button(action: {
                showingAddOrderView = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
            })
            .sheet(isPresented: $showingAddOrderView) {
                AddOrderView()
                    .environmentObject(orderManager)
                    .environmentObject(customerManager)
            }
            .sheet(item: $orderToEdit) { order in
                EditOrderView(order: binding(for: order))
                    .environmentObject(orderManager)
                    .environmentObject(customerManager)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this order? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let order = orderToDelete, let index = orderManager.orders.firstIndex(of: order) {
                            orderManager.orders.remove(at: index)
                        }
                        showDeleteConfirmation = false
                    },
                    secondaryButton: .cancel {
                        showDeleteConfirmation = false
                    }
                )
            }
        }
    }
    
    private func binding(for order: Order) -> Binding<Order> {
        guard let index = orderManager.orders.firstIndex(where: { $0.id == order.id }) else {
            fatalError("Order not found")
        }
        return $orderManager.orders[index]
    }

    private func handleDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            orderToDelete = orderManager.orders[index]
            showDeleteConfirmation = true
        }
    }
}

struct AddOrderView: View {
    @EnvironmentObject var orderManager: OrderManager
    @EnvironmentObject var customerManager: CustomerManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var toyName = ""
    @State private var quantity = ""
    @State private var customerName = ""
    @State private var status = "Pending"
    @State private var paymentStatus = "Unpaid"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Order Details")) {
                    TextField("Toy Name", text: $toyName)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    Picker("Customer", selection: $customerName) {
                        ForEach(customerManager.customers.map { $0.name }, id: \.self) { name in
                            Text(name)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    Picker("Order Status", selection: $status) {
                        Text("Pending").tag("Pending")
                        Text("Completed").tag("Completed")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    Picker("Payment Status", selection: $paymentStatus) {
                        Text("Unpaid").tag("Unpaid")
                        Text("Paid").tag("Paid")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                }
            }
            .navigationTitle("Add Order")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                guard let orderQuantity = Int(quantity) else { return }
                
                let totalPrice = Double(orderQuantity) * 100.0 // Assuming a flat rate per toy for simplicity
                let newOrder = Order(toyName: toyName, quantity: orderQuantity, totalPrice: totalPrice, customerName: customerName, orderDate: Date(), status: status, paymentStatus: paymentStatus)
                
                // Add the new order to the order manager
                orderManager.addOrder(newOrder)
                
                presentationMode.wrappedValue.dismiss()
            }.disabled(toyName.isEmpty || quantity.isEmpty || customerName.isEmpty))
        }
    }
}

struct EditOrderView: View {
    @Binding var order: Order
    @EnvironmentObject var orderManager: OrderManager
    @EnvironmentObject var customerManager: CustomerManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var quantity = ""

    var body: some View {
        Form {
            Section(header: Text("Order Details")) {
                TextField("Toy Name", text: $order.toyName)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                TextField("Quantity", text: $quantity)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .onAppear {
                        quantity = String(order.quantity)
                    }
                Picker("Customer", selection: $order.customerName) {
                    ForEach(customerManager.customers.map { $0.name }, id: \.self) { name in
                        Text(name)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                Picker("Order Status", selection: $order.status) {
                    Text("Pending").tag("Pending")
                    Text("Completed").tag("Completed")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                Picker("Payment Status", selection: $order.paymentStatus) {
                    Text("Unpaid").tag("Unpaid")
                    Text("Paid").tag("Paid")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            }
        }
        .navigationTitle("Edit Order")
        .navigationBarItems(trailing: Button("Save") {
            guard let orderQuantity = Int(quantity) else { return }
            order.quantity = orderQuantity
            order.totalPrice = Double(orderQuantity) * 100.0 // Assuming a flat rate per toy for simplicity
            presentationMode.wrappedValue.dismiss()
        }.disabled(order.toyName.isEmpty || quantity.isEmpty || order.customerName.isEmpty))
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
