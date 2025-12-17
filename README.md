# Compiler_final_project
使用語言: C++/lex/yacc

| 完成 | 項目                   | 分數 |
|----|----------------------|----|
| Y  | Syntax Validation    | 10 |
| Y  | Print                | 10 |
| Y  | Numerical Operations | 25 |
| Y  | Logical Operations   | 25 |
| Y  | if Expression        | 8  |
| Y  | Variable Definition  | 8  |
| Y  | Function             | 8  |
| Y  | Named Function       | 6  |
| Y  | Recursion            | 5  |
| Y  | Type Checking        | 5  |
| N  | Nested Function      | 5  |
| N  | First-class Function | 5  |


編譯和執行
```
#!/bin/bash
set -e 

# 確保 public_test_data 資料夾存在
if [ ! -d "public_test_data" ]; then
    echo "錯誤：找不到 public_test_data 資料夾！"
    exit 1
fi

echo "--- 1. 開始處理 Bison (C++ Mode) ---"
# -o 指定輸出成 .cpp 檔
bison -d -o project.tab.cpp project.y
# 使用 g++ 編譯，-std=c++11 是為了支援 vector 等現代寫法
g++ -c -g -I. -std=c++11 project.tab.cpp

echo "--- 2. 開始處理 Flex (C++ Mode) ---"
# -o 指定輸出成 .cpp 檔
flex -o lex.yy.cpp project.l
# 使用 g++ 編譯
# -Wno-deprecated-register 是為了消除一些舊版 flex 產生的警告
g++ -c -g -I. -std=c++11 lex.yy.cpp

echo "--- 3. 連結並產生執行檔 (project) ---"
# 全部用 g++ 連結
g++ -o project project.tab.o lex.yy.o -ll

echo "=== 編譯成功！開始執行所有測試案例 (輸出將直接印在下方) ... ==="
echo "================================================================="

for input_file in public_test_data/*.lsp; do
    if [ -f "$input_file" ]; then
        filename=$(basename -- "$input_file")
        
        echo ""
        echo "================================================================="
        echo "➡️ 測試案例：$filename"
        echo "================================================================="
        
        ./project < "$input_file" || { 
            echo ""
            echo "*** 警告：執行 $filename 時發生錯誤。 ***" 
        }
        
        echo ""
        echo "--- $filename 測試結束 ---"
    fi
done

echo "================================================================="
echo "=== 所有測試案例執行完畢！所有輸出已顯示在上方。 ==="
```
