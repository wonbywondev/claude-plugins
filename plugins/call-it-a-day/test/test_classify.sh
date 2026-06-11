# cad_classify <text> → morning | wrap | none
assert_eq "morning: 좋은 아침"              "morning" "$(cad_classify '좋은 아침')"
assert_eq "morning: 변형(굿모닝 좋은 아침)"  "morning" "$(cad_classify '굿모닝, 좋은 아침!')"
assert_eq "wrap: 하루 마무리하자"           "wrap"    "$(cad_classify '하루 마무리하자')"
assert_eq "wrap: 오늘 개발 여기서 마무리"    "wrap"    "$(cad_classify '오늘 개발 여기서 마무리하자')"
assert_eq "none: 일반 요청"                "none"    "$(cad_classify '이 버그 고쳐줘')"
assert_eq "none: '마무리' 단어 오탐 방지"   "none"    "$(cad_classify '마무리 로직 함수 리팩터링해줘')"
