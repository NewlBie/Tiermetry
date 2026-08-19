import os

def find_matching_paren(text, start_index):
    depth = 0
    for i in range(start_index, len(text)):
        if text[i] == '(': depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0: return i
    return -1

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    idx = 0
    modifications = []
    
    while True:
        idx = content.find('Text(', idx)
        if idx == -1: break
        
        end_idx = find_matching_paren(content, idx + 4)
        if end_idx == -1:
            idx += 5
            continue
            
        text_content = content[idx:end_idx+1]
        if 'TiermetryTypography.title' in text_content or 'TiermetryTypography.display' in text_content or 'TiermetryTypography.titleSmall' in text_content:
            # find the first argument
            arg_start = idx + 5
            depth = 0
            arg_end = -1
            for i in range(arg_start, end_idx):
                if content[i] == '(': depth += 1
                elif content[i] == ')': depth -= 1
                elif content[i] == ',' and depth == 0:
                    arg_end = i
                    break
            
            if arg_end != -1:
                first_arg = content[arg_start:arg_end].strip()
                if not first_arg.endswith('.toUpperCase()'):
                    # wrap first arg
                    new_first_arg = f'({first_arg}).toUpperCase()'
                    modifications.append((arg_start, arg_end, new_first_arg))
        idx += 5

    if modifications:
        offset = 0
        new_content = content
        for start, end, new_text in modifications:
            start += offset
            end += offset
            new_content = new_content[:start] + new_text + new_content[end:]
            offset += len(new_text) - (end - start)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def main():
    with open('title_usages.txt', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    files = set()
    for line in lines:
        if ':' in line:
            files.add(line.split(':')[0])
            
    for file in files:
        if os.path.exists(file):
            process_file(file)

if __name__ == '__main__':
    main()
