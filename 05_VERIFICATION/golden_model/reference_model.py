PATTERN = "10110"

def detect(stream, overlap=True):
    window = ""
    matches = []
    for pos, bit in enumerate(stream, start=1):
        window = (window + bit)[-5:]
        if window == PATTERN:
            matches.append(pos)
            if not overlap:
                window = ""
    return matches

def run():
    assert detect("10110", True) == [5]
    assert detect("0010110", True) == [7]
    assert detect("000000", True) == []
    assert detect("1011011010", True) == [5, 8]
    assert detect("1011011010", False) == [5]

    print("E06 reference model PASS")
    print("overlap    1011011010 ->", detect("1011011010", True))
    print("nonoverlap 1011011010 ->", detect("1011011010", False))

if __name__ == "__main__":
    run()
