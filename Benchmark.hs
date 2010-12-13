import Text.Pandoc
import Text.Pandoc.Shared (readDataFile)
import Criterion.Main
import Data.List (isSuffixOf)

readerBench :: Pandoc
            -> (String, ParserState -> String -> Pandoc)
            -> Benchmark
readerBench doc (name, reader) =
  let writer = case lookup name writers of
                     Just w  -> w
                     Nothing -> error $ "Could not find writer for " ++ name
      inp = writer defaultWriterOptions{ writerWrapText = True
                                       , writerLiterateHaskell =
                                          "+lhs" `isSuffixOf` name } doc
  in  bench (name ++ " reader") $ whnf
        (reader defaultParserState{stateSmart = True
                                  , stateStandalone = True
                                  , stateLiterateHaskell =
                                      "+lhs" `isSuffixOf` name }) inp

writerBench :: Pandoc
            -> (String, WriterOptions -> Pandoc -> String)
            -> Benchmark
writerBench doc (name, writer) = bench (name ++ " writer") $ nf
    (writer defaultWriterOptions{
                   writerWrapText = True
                  , writerLiterateHaskell = "+lhs" `isSuffixOf` name }) doc

main = do
  inp <- readDataFile (Just ".") "README"
  let ps = defaultParserState{ stateSmart = True }
  let doc = readMarkdown ps inp
  let readerBs = map (readerBench doc) readers
  defaultMain $ map (writerBench doc) writers ++ readerBs

