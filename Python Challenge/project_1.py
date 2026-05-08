while 1==1:
    
    # Lời chào
    print("\n\U0001F4D0 WELCOME TO LENGTH CONVERTER \U0001F4D0\n")
    
    # Bước 1: Tạo danh mục, đối chiếu đơn vị đo
    dict_Length = {'meter':1, 'kilometer':0.001, 'centimeter':100, 'millimeter':1000, 'micrometer':10**6, 'nanometer':10**9 }
    
    
    # Bước 2: Nhập các biến đầu vào ________________________________________________________
    # Đơn vị user nhập, ko bị sai chính tả, ko phải đơn vị ngoài, ko dính lỗi in hoa
    # Value user nhập là number >= 0
    print('Available units of Length:                                      ') 
    print(*list(dict_Length.keys()), sep=", ")
    print('_____________________________\n')
    
    # Bước 2.1: nhập đơn vị đầu vào 
    while 1==1:
        unit_in = str(input('Enter starting unit of Length: ')).lower()
        if unit_in in list(dict_Length.keys()):
            break
        else:
            print(f"\n\u26A0 '{unit_in}' is not in available units list!")
            print(f'\u26A0 Please provide a available unit in list!')
    
    
    # Bước 2.1: nhập đơn vị đầu ra 
    while 1==1:
        unit_out = str(input('Enter unit of Length to convert to: ')).lower()
        if unit_in in list(dict_Length.keys()):
            break
        else:
            print(f"\n\u26A0 '{unit_in}' is not in available units list!")
            print(f'\u26A0 Please provide a available unit in list!')        
    
    
    #Bước 2.3: nhập giá trị muốn đổi
    while 1==1:
        try:
            value_in = float(input(f'Enter the value to convert in {unit_in}: '))
            if value_in < 0:
                print("\u26A0 Please enter a number >= 0!")
                continue
            break
        except Exception:
            print(f'\n\u26A0 Please provide a valid number!')
    
    
    # Bước 3: Tính toán & đưa ra kết quả ______________________________________________________
    value_out = value_in * dict_Length[unit_out] / dict_Length[unit_in]
    print(f'\nResult: {value_in} {unit_in} = {value_out} {unit_out}')
    
    # Bước 4: Hỏi user còn muốn chuyển đổi đơn vị tiếp ko ?
    print('_____________________________\n')
    key = str(input('\nDo you want to perform another conversion? (Y/N): ')).upper()
    if key == 'N':
        print("Thank you for using this Length Converter! \U0001F33B\n\n\n")
        break
    else: 
        print('\n\n\n')
        
        # 1 m =  0.001 km
        # 2 m = 2 * 0.001/1 km