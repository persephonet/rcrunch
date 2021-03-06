context("Cube queries with on-the-fly expressions")

with_test_authentication({
    ds <- newDatasetFromFixture("apidocs")
    test_that("<, <= on numeric", {
        # ndogs
        # 0 1 2 3 6
        # 2 3 7 3 1
        expect_equivalent(as.array(crtabs(~ ndogs < 2, data=ds)), 5)
        expect_equivalent(as.array(crtabs(~ ndogs <= 2, data=ds)), 12)
        expect_equivalent(as.array(crtabs(~ ndogs > 2, data=ds)), 4)
        expect_equivalent(as.array(crtabs(~ ndogs >= 2, data=ds)), 11)
        expect_equivalent(as.array(crtabs(~ ndogs > 1 & ndogs <=3, data=ds)), 10)
    })

    test_that("%in% with categorical", {
        # q1
        #  Cat  Dog Bird
        #    6    4    3
        skip("(400) Bad Request: The truth value of an array with more than one element is ambiguous. Use a.any() or a.all()")
        expect_equivalent(as.array(crtabs(~ q1 %in% c("Cat", "Dog"),
            data=ds)), 10)
        expect_equivalent(as.array(crtabs(~ !(q1 %in% c("Cat", "Dog")),
            data=ds)), 3)
    })

    test_that("==, != with categorical", {
        expect_equivalent(as.array(crtabs(~ q1 == "Cat",
            data=ds)), 6)
        expect_equivalent(as.array(crtabs(~ q1 != "Cat" & !is.na(q1),
            data=ds)), 7)
    })
})
