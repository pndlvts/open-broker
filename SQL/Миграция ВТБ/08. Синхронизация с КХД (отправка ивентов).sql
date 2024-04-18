USE [CIS.Buffer]
GO

IF ColumnProperty(Object_Id('[CIS.Buffer].[Migration].[Contracts?Close]'), 'IsEventSent', 'ColumnId') IS NULL BEGIN
    ALTER TABLE [Migration].[Contracts?Close]
        ADD [IsEventSent]     Bit     default(0) NOT NULL;
END;
GO

USE [CIS.Middle]
GO
SET NOCOUNT ON;
SET DEADLOCK_PRIORITY LOW;

DECLARE
    @Tranche_Id                     Int                             = ,                     -- Указать номер транша
    @Action                         NVarChar(50)                    = 'CloseBrokContracts', -- 'CloseDepoContracts'
    @SendToAltESB                   Bit                             = 0,                    -- Оправлять в FTPS (0 - нет, 1 - да)
    @BatchSize                      Int                             = 100,
    @Quantity                       Int                             = 5000,                 -- количество договоров за запуск
    @BatchDelay                     Char(8)                         = '00:00:10',
    @StepDelay                      Char(8)                         = '00:00:00.5';


DECLARE
    @DeadLockRetries                TinyInt                         = 5,
    @DeadLockDelay                  DateTime                        = '00:00:01',
    @SavePoint                      SysName                         = 'TRAN_' + Suser_Name() + '_' + Cast(NewId() AS NVarChar(50)),
    @TranCount                      Int,
    @Retry                          TinyInt,
    @ErrorNumber                    Int,

    @Batch_Id                       Int,
    @MaxBatch_Id                    Int,
    @BatchNumber                    Int                             = 0,

    @DebugMessage                   VarChar(Max),
    @DateTimeFormat                 NVarChar(64)                    = 'dd.mm.yyyy hh.nn.ss.fff',
    @DateTimeString                 NVarChar(100),

    @Status_Id_CREATE               Char(1)                         = [Base].[Objects:Statuses->Types@Get?Id]('CREATE'),
    @Status_Id_SIGNED               Char(1)                         = [Base].[Objects:Statuses->Types@Get?Id]('SIGNED'),
    @Status_Id_TERMINATIONSTARTED   Char(1)                         = [Base].[Objects:Statuses->Types@Get?Id]('TERMINATION-STARTED'),
    @Status_Id_ACCEPTED             Char(1)                         = [Base].[Objects:Statuses->Types@Get?Id]('ACCEPTED'),
    @Status_Id_FINISHED             Char(1)                         = [Base].[Objects:Statuses->Types@Get?Id]('FINISHED'),

    @Contract_Id                    Int,
    @Person_Id                      Int,
    @DateTo                         Date,
    @RowIndex                       Int,
    @RowCount                       Int;


DECLARE @Contracts  Table
(
    [Identity]                      Int  IDENTITY(1,1) PRIMARY KEY      NOT NULL,
    [Id]                            Int                                 NOT NULL,
    [Contract_Id]                   Int                                 NOT NULL,
    [Contract_GUId]                 UniqueIdentifier                    NOT NULL,
    [Person_Id]                     Int                                 NOT NULL,
    [DateTo]                        Date                                NOT NULL,
    [Type_Id]                       TinyInt                             NOT NULL,
    [Batch_Id]                      SmallInt                            NOT NULL
    
);

    IF @Tranche_Id IS NULL
        RaisError('Не задан номер транша!', 16, 2);

    INSERT INTO @Contracts
    (
        [Id],
        [Contract_Id],
        [Contract_GUId],
        [Person_Id],
        [DateTo],
        [Type_Id],
        [Batch_Id]
    )
    SELECT TOP (@Quantity)
        [Id]                            = M.[Id],
        [Contract_Id]                   = C.[Id],
        [Contract_GUId]                 = GC.[GUId],
        [Person_Id]                     = C.[Person_Id],
        [DateTo]                        = C.[DateTo],
        [Type_Id]                       = C.[Type_Id],
        [Batch_Id]                      = (Row_Number() OVER (ORDER BY (SELECT NULL)) - 1) / @BatchSize + 1
    FROM [CIS.Buffer].[Migration].[Contracts?Close]                 M
    INNER JOIN [Base].[Objects:GUIds]                               GC  ON  GC.[GUId] = M.[Contract_GUId]
    INNER JOIN [FrontOffice].[Contracts]                            C   ON  C.[Id] = GC.[Id]
    WHERE M.[Tranche_Id] = @Tranche_Id
      AND M.[Action] = @Action
      AND M.[Processed] = 1
      AND M.[IsManual] = 0
      AND M.[IsEventSent] = 0
      AND C.[Status_Id] = @Status_Id_FINISHED;

    SET @MaxBatch_Id  = IsNull((SELECT Max([Batch_Id]) FROM @Contracts), -1);
    SET @Batch_Id  = (SELECT Min([Batch_Id]) FROM @Contracts);

BEGIN TRY

    WHILE (@Batch_Id <= @MaxBatch_Id) BEGIN

        IF (@Batch_Id > 1)
            WAITFOR DELAY @BatchDelay;

            -----------------------------------------
            -- Работаем внутри транзакции
            -----------------------------------------
            SET @DateTimeString = [Pub].[Format DateTime](@DateTimeFormat, GetDate());
            SET @DebugMessage = FormatMessage('Start @Batch_Id = %d из %d - %s', @Batch_Id, @MaxBatch_Id, @DateTimeString);
            RaisError('%s', 0, 0, @DebugMessage) WITH NOWAIT;

            SET @RowIndex = -1;
            WHILE (1 = 1) BEGIN
                SELECT TOP (1)
                    @RowIndex                       = C.[Identity],
                    @Contract_Id                    = C.[Contract_Id],
                    @Person_Id                      = C.[Person_Id],
                    @DateTo                         = C.[DateTo]
                FROM @Contracts                 C
                WHERE   C.[Identity] > @RowIndex
                AND [Batch_Id] = @Batch_Id
                ORDER BY
                    C.[Identity];

                IF @@RowCount = 0
                    BREAK;

                WAITFOR DELAY @StepDelay;

                EXEC [MiddleOffice].[Event=FrontOffice.Contract:Changed@Execute(Internal)]
                    @Contract_Id        = @Contract_Id,
                    @SendToAltESB       = @SendToAltESB,
                    @ParentRequest_Id   = NULL;

                IF EXISTS(
                    SELECT 
                        1 
                    FROM [Base].[Persons:Relations] T
                    CROSS APPLY (SELECT TOP(1) V.[Date], V.[Value] FROM [Base].[Periodic:Values] V WHERE V.[Field_Id] = 81 AND V.[Key] = T.[Id]  ORDER BY V.[Date] DESC) V81
                    OUTER APPLY (SELECT TOP(1) V.[Date], V.[Value] FROM [Base].[Periodic:Values] V WHERE V.[Field_Id] = 103 AND V.[Key] = T.[Id]  ORDER BY V.[Date] DESC) V103
                    WHERE T.[Person_Id] = @Person_Id
                        AND (V81.[Date] >= @DateTo OR V103.[Date] >= @DateTo)
                    ) BEGIN

                        EXEC [MiddleOffice].[Event=Base.Person:Changed@Execute(Internal)]
                            @Person_Id          = @Person_Id,
                            @SendToAltESB       = @SendToAltESB,
                            @ParentRequest_Id   = NULL;

                END

            END;

            -- Фиксирование результата в таблице логирования
            UPDATE M
               SET
                    [IsEventSent]         = Cast(1 AS Bit)
            FROM [CIS.Buffer].[Migration].[Contracts?Close]             M
            INNER JOIN @Contracts                                       C ON M.[Id] = C.[Id]
            WHERE C.[Batch_Id] = @Batch_Id;

            ------------------------------------------------------------------------
            -- Финиш (внутри транзакции)
            ------------------------------------------------------------------------
        FINALLY:
            SET @Batch_Id = @Batch_Id + 1;

    END;
END TRY
BEGIN CATCH
    IF @@TranCount > 0
        ROLLBACK TRAN;

    EXEC [System].[ReRaise Error] @ProcedureId = @@ProcId;
END CATCH;
GO