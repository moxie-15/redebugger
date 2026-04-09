Redebugger: Hybrid CBT Ecosystem
Redebugger is a robust, full-stack Computer-Based Testing (CBT) application built with Flutter. It’s engineered to bridge the gap between cloud-based synchronization and local-first reliability, ensuring that students can take exams anytime, anywhere—with or without a steady internet connection.

⚡ Core Functionality
Hybrid Sync Engine: Seamlessly transition between online and offline modes. Data stays in sync whenever a connection is detected.

Local-First Persistence: Powered by Isar Database, ensuring the app remains fully functional and snappy even in complete dead zones.

Cloud Integration: Fetches real-time exam updates, user profiles, and global rankings from the backend.

Optimized Performance: Built for speed and efficiency, minimizing latency during high-pressure testing scenarios.

🛠 Tech Stack
Framework: Flutter

Getting Started
Installation
Clone the repository:

Bash
git clone https://github.com/your-username/redebugger.git
Fetch Flutter packages:

Bash
flutter pub get
Generate Isar Schemas:

Bash
dart run build_runner build
Run the application:

Bash
flutter run
🏗 System Architecture
The app uses a Repository Pattern to abstract the data source. Whether data comes from the remote API or the Isar local store, the UI remains reactive and decoupled, ensuring a smooth user experience regardless of the network state.

🛤 Roadmap
[ ] Real-time cloud-sync for live proctoring.

[ ] Adaptive testing algorithms based on student performance.

[ ] Cross-platform support (Web & Desktop).
