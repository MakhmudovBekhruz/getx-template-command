# getx.sh

A simple **Bash CLI tool** for macOS/Linux that generates a [GetX](https://pub.dev/packages/get) page folder structure for your Flutter projects.  
It enforces consistent naming (`snake_case` for files & folders, `PascalCase` for classes) and supports multiple input styles (`MyPage`, `my_page`, `my-page`, `my page`, `MyHTTPPage`).

---

## ✨ Features

- ✅ Generates a **feature folder** with `snake_case` name.  
- ✅ Creates a `widget` subfolder inside.  
- ✅ Generates **5 Dart files**:
  - `*_binding.dart`
  - `*_logic.dart`
  - `*_logic_impl.dart`
  - `*_state.dart`
  - `*_view.dart`
- ✅ Ensures proper class naming (`ForgotPasswordLogic`, `ForgotPasswordState`, etc.).  
- ✅ Preserves acronyms (`MyHTTPPage` → `MyHTTPPage`).  
- ✅ Safety: won’t overwrite existing files unless `-f` is passed.  
- ✅ Dry-run mode (`-n`) to preview without writing files.  

---

## 📦 Installation

Clone or download the script, then install globally:

```bash
chmod +x getx.sh
sudo mv getx.sh /usr/local/bin/getx
