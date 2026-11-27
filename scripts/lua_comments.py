from pathlib import Path
import re

def segments(source):
    i=0
    while i<len(source):
        start=i
        if source.startswith('--',i):
            match=re.match(r'--\[(=*)\[',source[i:])
            if match:
                close=']'+match[1]+']'
                end=source.find(close,i+len(match[0]))
                i=len(source) if end<0 else end+len(close)
            else:
                end=source.find('\n',i)
                i=len(source) if end<0 else end
            yield True,source[start:i]
        elif source[i] in ('"',"'",'`'):
            quote=source[i];i+=1
            while i<len(source):
                if source[i]=='\\': i+=2
                elif source[i]==quote: i+=1;break
                else: i+=1
            yield False,source[start:i]
        elif source[i]=='[' and (match:=re.match(r'\[(=*)\[',source[i:])):
            close=']'+match[1]+']'
            end=source.find(close,i+len(match[0]))
            i=len(source) if end<0 else end+len(close)
            yield False,source[start:i]
        else:
            i+=1
            yield False,source[start:i]

def strip(source):
    return ''.join((' '+''.join(c for c in text if c in '\n\r')) if comment else text for comment,text in segments(source))

def tidy(source):
    out=[]
    for _,text in segments(strip(source)):
        if len(text)>1:
            out.append(text)
        else:
            if text in ('\n','\r'):
                while out and out[-1] in (' ','\t'):out.pop()
            out.append(text)
    while out and out[-1] in (' ','\t'):out.pop()
    return ''.join(out)

def clean_tree(root):
    for path in root.rglob('*'):
        if path.suffix not in ('.lua','.luau') or 'node_modules' in path.parts or '.git' in path.parts: continue
        source=path.read_text();result=tidy(source)
        if result!=source:path.write_text(result)
        assert not any(comment for comment,_ in segments(result)),str(path)

if __name__=='__main__':
    clean_tree(Path(__file__).resolve().parents[1])
